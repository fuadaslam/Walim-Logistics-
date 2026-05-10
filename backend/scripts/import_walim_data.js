const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const WALIM_API_BASE_URL = process.env.WALIM_API_BASE_URL || 'https://www.walim.sa';
const WALIM_API_TOKEN = process.env.WALIM_API_TOKEN;
const WALIM_USERNAME = process.env.WALIM_USERNAME;
const WALIM_PASSWORD = process.env.WALIM_PASSWORD;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('Missing Supabase environment variables.');
  process.exit(1);
}

const ws = require('ws');
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    persistSession: false
  },
  realtime: {
    transport: ws
  }
});

let walimApi;

async function authenticate() {
  let token = WALIM_API_TOKEN;

  if (!token && WALIM_USERNAME && WALIM_PASSWORD) {
    console.log('No token provided. Attempting to login to Walim Portal...');
    try {
      const response = await axios.post(`${WALIM_API_BASE_URL}/api/account/auth`, {
        email: WALIM_USERNAME,
        password: WALIM_PASSWORD
      });
      token = response.data.data?.token || response.data.token;
      if (!token) throw new Error('Authentication failed: No token returned');
      console.log('Login successful.');
    } catch (error) {
      console.error('Login failed:', error.message);
      process.exit(1);
    }
  }

  if (!token) {
    console.error('No WALIM_API_TOKEN or WALIM_USERNAME/PASSWORD provided.');
    process.exit(1);
  }

  walimApi = axios.create({
    baseURL: WALIM_API_BASE_URL,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
}

async function run() {
  try {
    await authenticate();
    console.log('Starting data synchronization from Walim Portal API...');

    // 1. Fetch roles from Supabase
    console.log('Fetching roles from Supabase...');
    const { data: roles, error: rolesError } = await supabase.from('roles').select('id, name');
    if (rolesError) throw rolesError;
    const roleMap = Object.fromEntries(roles.map(r => [r.name.toLowerCase(), r.id]));
    console.log(`Loaded ${roles.length} roles.`);

    // 2. Fetch Users from Walim API
    console.log('Fetching users from Walim API...');
    const targetRoles = [
      'Riders', 'Supervisors', 'OperationManager', 'HR', 'Finance', 
      'InformationTechnology', 'Mechanic', 'Administrative Assistant', 
      'Sales Representative', 'Marketing Specialist', 'OfficeBoy', 'OfficeClerk', 'Support'
    ];

    for (const roleName of targetRoles) {
      console.log(`Fetching users for role: ${roleName}...`);
      try {
        const usersResponse = await walimApi.get(`/api/account/users?KYC=all&UserRoles=${roleName}&EmployeeType=all&RiderAppName=all&takeRecords=all`);
        const walimUsers = usersResponse.data.data || usersResponse.data || []; 
        console.log(`Fetched ${walimUsers.length} users for role ${roleName}.`);
        
        for (const item of walimUsers) {
          await syncUser(item, roleMap);
        }
      } catch (error) {
        console.error(`Failed to fetch users for role ${roleName}:`, error.message);
      }
    }

    // 3. Fetch Vehicles from Walim API
    console.log('Fetching vehicles from Walim API...');
    const vehiclesResponse = await walimApi.get('/api/vehicles?takeRecords=all');
    const walimVehicles = vehiclesResponse.data.data || [];
    console.log(`Fetched ${walimVehicles.length} vehicles from Walim.`);

    for (const vehicle of walimVehicles) {
      await syncVehicle(vehicle);
    }

    console.log('Data synchronization completed successfully.');
  } catch (error) {
    console.error('Error during synchronization:', error.message);
    if (error.response) {
      console.error('API Response Data:', error.response.data);
    }
  }
}

async function syncUser(item, roleMap) {
  try {
    const user = item.user;
    if (!user || !user.id) {
      console.warn('Skipping invalid user item:', JSON.stringify(item));
      return;
    }

    const externalId = user.id.toString();
    const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.userName || 'Unknown User';
    const phone = normalizePhone(user.userVM?.phoneNumber || user.phoneNumber);
    const iqama = user.iqamaID;
    
    // Map role
    const sourceRole = (item.roles || 'Rider').toLowerCase();
    const roleId = mapRole(sourceRole, roleMap);

    // 1. Check if profile exists
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('external_id', externalId)
      .maybeSingle();

    let profileId;

    if (existingProfile) {
      profileId = existingProfile.id;
      
      // Force update password for existing Auth user to match the new standard
      await supabase.auth.admin.updateUserById(profileId, {
        password: 'Walim@2026!',
        user_metadata: { require_password_reset: true }
      });

      // Update profile
      const { error: updateError } = await supabase.from('profiles').update({
        full_name: fullName,
        phone_number: phone,
        iqama_number: iqama,
        role_id: roleId,
        status: mapUserStatus(user.employeesVM?.isActive ?? true)
      }).eq('id', profileId);
      
      if (updateError) throw updateError;
      console.log(`Updated profile and reset password for ${fullName} (${externalId})`);
    } else {
      // 2. Create Auth User if it doesn't exist
      const email = user.userVM?.email || user.email || `${iqama || externalId}@walim.internal`;
      
      // Clean up email (Walim sometimes puts commas/phones in email field)
      const cleanEmail = email.split(',')[0].trim();

      const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
        email: cleanEmail,
        phone: phone,
        password: 'Walim@2026!', 
        email_confirm: true,
        phone_confirm: true,
        user_metadata: { 
          full_name: fullName,
          require_password_reset: true 
        }
      });

      if (authError) {
        if (authError.message.includes('already registered')) {
          console.warn(`Auth user ${cleanEmail} already exists. Skipping profile creation.`);
          return;
        }
        throw authError;
      }

      profileId = authUser.user.id;

      // 3. Create Profile
      const { error: profileError } = await supabase.from('profiles').upsert({
        id: profileId,
        external_id: externalId,
        full_name: fullName,
        phone_number: phone,
        iqama_number: iqama,
        role_id: roleId,
        status: mapUserStatus(user.employeesVM?.isActive ?? true)
      });

      if (profileError) throw profileError;
      console.log(`Created new profile for ${fullName} (${externalId})`);
    }
  } catch (error) {
    console.error(`Failed to sync user:`, error.message);
  }
}

async function syncVehicle(vehicle) {
  try {
    const externalId = vehicle.id.toString();
    
    const vehicleData = {
      external_id: externalId,
      plate_number: vehicle.plateNumber,
      vin_number: vehicle.chassisNumber || vehicle.vin,
      make: vehicle.manufacturerStr || vehicle.make,
      model: vehicle.model,
      year: parseInt(vehicle.year),
      type: mapVehicleType(vehicle.vehicleTypeStr || vehicle.type),
      status: mapVehicleStatus(vehicle.vehicleStatus || vehicle.status),
      istimara_expiry: vehicle.registrationExpiryDate,
    };

    const { error } = await supabase
      .from('vehicles')
      .upsert(vehicleData, { onConflict: 'external_id' });

    if (error) throw error;
    console.log(`Synced vehicle ${vehicle.plateNumber} (${externalId})`);
  } catch (error) {
    console.error(`Failed to sync vehicle ${vehicle.id}:`, error.message);
  }
}

function normalizePhone(phone) {
  if (!phone) return null;
  let cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('05')) cleaned = '966' + cleaned.substring(1);
  if (cleaned.startsWith('5')) cleaned = '966' + cleaned;
  return `+${cleaned}`;
}

function mapRole(sourceRole, roleMap) {
  const mapping = {
    'rider': 'Rider',
    'driver': 'Rider',
    'supervisor': 'Supervisor',
    'team_lead': 'Supervisor',
    'hr': 'HR',
    'admin': 'Admin',
    'finance': 'Finance Manager',
    'operations': 'Operations Manager',
    'it': 'IT_Dev',
    'developer': 'IT_Dev',
    'leader': 'Leader'
  };
  const targetName = mapping[sourceRole] || 'Rider';
  return roleMap[targetName.toLowerCase()];
}

function mapUserStatus(status) {
  if (status === true || status === 'Active' || status === 'active') return 'active';
  if (status === 'on_leave') return 'on_leave';
  if (status === 'suspended') return 'suspended';
  return 'inactive';
}

function mapVehicleType(type) {
  if (!type) return 'other';
  const t = type.toLowerCase();
  if (t.includes('bike')) return 'bike';
  if (t.includes('car')) return 'car';
  if (t.includes('van')) return 'van';
  if (t.includes('truck')) return 'truck';
  return 'other';
}

function mapVehicleStatus(status) {
  if (status === 'Active' || status === 'available') return 'available';
  if (status === 'In Use' || status === 'assigned') return 'in_use';
  if (status === 'Maintenance') return 'maintenance';
  return 'retired';
}

run();
