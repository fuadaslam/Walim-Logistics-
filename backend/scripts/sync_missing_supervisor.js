const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const WALIM_API_BASE_URL = process.env.WALIM_API_BASE_URL || 'https://www.walim.sa';
const WALIM_API_TOKEN = process.env.WALIM_API_TOKEN;
const WALIM_USERNAME = process.env.WALIM_USERNAME;
const WALIM_PASSWORD = process.env.WALIM_PASSWORD;

const ws = require('ws');
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
  realtime: { transport: ws }
});

let walimApi;

async function authenticate() {
  let token = WALIM_API_TOKEN;
  if (!token && WALIM_USERNAME && WALIM_PASSWORD) {
    const response = await axios.post(`${WALIM_API_BASE_URL}/api/account/auth`, {
      email: WALIM_USERNAME,
      password: WALIM_PASSWORD
    });
    token = response.data.data?.token || response.data.token;
    if (!token) throw new Error('Authentication failed');
    console.log('Login successful.');
  }
  walimApi = axios.create({
    baseURL: WALIM_API_BASE_URL,
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  });
}

async function run() {
  try {
    await authenticate();

    // Fetch Supervisor role ID from Supabase
    const { data: roles } = await supabase.from('roles').select('id, name');
    const roleMap = Object.fromEntries(roles.map(r => [r.name.toLowerCase(), r.id]));
    const supervisorRoleId = roleMap['supervisor'];
    if (!supervisorRoleId) throw new Error('Supervisor role not found in Supabase');

    // Fetch all supervisors from Walim API
    console.log('Fetching Supervisors from Walim API...');
    const response = await walimApi.get('/api/account/users?KYC=all&UserRoles=Supervisors&EmployeeType=all&RiderAppName=all&takeRecords=all');
    const walimSupervisors = response.data.data || response.data || [];
    console.log(`Fetched ${walimSupervisors.length} supervisors from Walim.`);

    // Find Fahad Kathiri by iqama or name
    const target = walimSupervisors.find(item => {
      const u = item.user || item;
      const iqama = u.iqamaID || '';
      const name = `${u.firstName || ''} ${u.lastName || ''}`.toLowerCase();
      return iqama === '2600508523' || name.includes('fahad') && name.includes('kathir');
    });

    if (!target) {
      console.error('Fahad Kathiri not found in Walim API response.');
      console.log('Listing all fetched supervisors for manual check:');
      walimSupervisors.forEach(item => {
        const u = item.user || item;
        console.log(` - ${u.firstName} ${u.lastName} | iqama: ${u.iqamaID} | email: ${u.userVM?.email || u.email}`);
      });
      return;
    }

    const u = target.user || target;
    console.log(`Found: ${u.firstName} ${u.lastName} (iqama: ${u.iqamaID})`);

    // Check if already exists in Supabase by external_id or iqama
    const externalId = u.id.toString();
    const { data: existing } = await supabase
      .from('profiles')
      .select('id')
      .or(`external_id.eq.${externalId},iqama_number.eq.${u.iqamaID}`)
      .maybeSingle();

    if (existing) {
      console.log('Profile already exists — updating role to Supervisor only.');
      await supabase.from('profiles').update({ role_id: supervisorRoleId }).eq('id', existing.id);
      console.log('Done.');
      return;
    }

    // Create auth user
    const rawEmail = u.userVM?.email || u.email || `${u.iqamaID || externalId}@walim.internal`;
    const email = rawEmail.split(',')[0].trim();
    const phone = normalizePhone(u.userVM?.phoneNumber || u.phoneNumber);
    const fullName = `${u.firstName || ''} ${u.lastName || ''}`.trim() || 'Unknown';

    console.log(`Creating auth user: ${email}`);
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email,
      ...(phone ? { phone } : {}),
      password: 'Walim@2026!',
      email_confirm: true,
      ...(phone ? { phone_confirm: true } : {}),
      user_metadata: { full_name: fullName, require_password_reset: true }
    });

    if (authError) throw authError;

    const profileId = authUser.user.id;

    const { error: profileError } = await supabase.from('profiles').upsert({
      id: profileId,
      external_id: externalId,
      full_name: `${fullName} (Walim)`,
      phone_number: phone,
      iqama_number: u.iqamaID,
      role_id: supervisorRoleId,
      status: 'active'
    });

    if (profileError) throw profileError;
    console.log(`✓ Successfully created profile for ${fullName} (Walim)`);

  } catch (err) {
    console.error('Error:', err.message);
    if (err.response) console.error('API:', err.response.data);
  }
}

function normalizePhone(phone) {
  if (!phone) return null;
  let cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('05')) cleaned = '966' + cleaned.substring(1);
  else if (cleaned.startsWith('5') && cleaned.length === 9) cleaned = '966' + cleaned;
  else if (cleaned.startsWith('966') && cleaned.length === 12) { /* already good */ }
  else return null; // unrecognized format — skip phone
  return `+${cleaned}`;
}

run();
