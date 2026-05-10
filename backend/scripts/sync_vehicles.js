const { createClient } = require('@supabase/supabase-js');
const axios = require('axios');
require('dotenv').config();

const ws = require('ws');
const WALIM_API_BASE_URL = process.env.WALIM_API_BASE_URL || 'https://www.walim.sa';

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
  realtime: { transport: ws }
});

let walimApi;

async function authenticate() {
  let token = process.env.WALIM_API_TOKEN;
  if (!token) {
    const res = await axios.post(`${WALIM_API_BASE_URL}/api/account/auth`, {
      email: process.env.WALIM_USERNAME,
      password: process.env.WALIM_PASSWORD
    });
    token = res.data.data?.token || res.data.token;
    if (!token) throw new Error('Auth failed');
    console.log('Login successful.');
  }
  walimApi = axios.create({
    baseURL: WALIM_API_BASE_URL,
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  });
}

function mapVehicleType(type) {
  if (!type) return 'other';
  const t = type.toLowerCase();
  if (t.includes('bike') || t.includes('motorcycle')) return 'bike';
  if (t.includes('scooter')) return 'scooter';
  if (t.includes('electric')) return 'electric_bike';
  if (t.includes('van')) return 'van';
  if (t.includes('truck')) return 'truck';
  if (t.includes('bus')) return 'bus';
  if (t.includes('pickup')) return 'pickup';
  if (t.includes('car')) return 'car';
  return 'other';
}

function mapVehicleStatus(status) {
  if (!status) return 'available';
  const s = status.toString().toLowerCase();
  if (s === 'active' || s === 'available') return 'available';
  if (s === 'onduty' || s === 'on_duty' || s === 'in use' || s === 'inuse' || s === 'assigned') return 'in_use';
  if (s === 'maintenance' || s === 'majorbreakdown' || s === 'major_breakdown' || s === 'accident') return 'maintenance';
  if (s === 'spare' || s === 'duplicateentry' || s === 'inactive' || s === 'retired') return 'retired';
  return 'available';
}

async function run() {
  try {
    await authenticate();

    console.log('Fetching all vehicles from Walim API...');
    const res = await walimApi.get('/api/vehicles?takeRecords=all');
    const walimVehicles = res.data.data || res.data || [];
    console.log(`Fetched ${walimVehicles.length} vehicles from Walim.\n`);

    // Build profile lookup: external_id (UUID) → profile.id (UUID)
    const { data: profiles } = await supabase.from('profiles').select('id, external_id').not('external_id', 'is', null);
    const profileByExternalId = {};
    for (const p of profiles || []) {
      profileByExternalId[p.external_id] = p.id;
    }
    console.log(`Loaded ${Object.keys(profileByExternalId).length} profiles for assignment lookup.\n`);

    // Fetch existing DB vehicles for plate/vin fallback matching
    const { data: dbVehicles } = await supabase.from('vehicles').select('id, external_id, plate_number, vin_number');
    const byPlate = {};
    const byVin = {};
    for (const v of dbVehicles || []) {
      if (v.plate_number) byPlate[v.plate_number.trim().toLowerCase()] = v;
      if (v.vin_number) byVin[v.vin_number.trim().toLowerCase()] = v;
    }

    let inserted = 0, updated = 0, failed = 0;

    for (const vehicle of walimVehicles) {
      const externalId = vehicle.id?.toString();
      if (!externalId) continue;

      // Resolve assigned_profile_id via vehicle.userID → profiles.external_id
      const assignedProfileId = vehicle.userID ? (profileByExternalId[vehicle.userID] || null) : null;

      const vehicleData = {
        external_id: externalId,
        plate_number: vehicle.plateNumber,
        vin_number: vehicle.chassisNumber || vehicle.vin || null,
        make: vehicle.manufacturerStr || vehicle.make || null,
        model: vehicle.model || null,
        year: vehicle.year ? parseInt(vehicle.year) : null,
        type: mapVehicleType(vehicle.vehicleTypeStr || vehicle.type),
        status: mapVehicleStatus(vehicle.vehicleStatus || vehicle.status),
        istimara_expiry: vehicle.registrationExpiryDate || null,
        mvpi_expiry: vehicle.mvpiExpiryDate || null,
        insurance_expiry: vehicle.insuranceExpiryDate || null,
        assigned_profile_id: assignedProfileId,
      };

      // Try upsert by external_id first
      const { error: upsertError } = await supabase
        .from('vehicles')
        .upsert(vehicleData, { onConflict: 'external_id' });

      if (!upsertError) {
        // Check if it was an insert or update
        const plate = vehicle.plateNumber?.trim().toLowerCase();
        const vin = (vehicle.chassisNumber || vehicle.vin)?.trim().toLowerCase();
        if ((plate && byPlate[plate]) || (vin && byVin[vin])) {
          updated++;
        } else {
          inserted++;
        }
        continue;
      }

      // Fallback: find by plate_number or vin and backfill external_id
      const plate = vehicle.plateNumber?.trim().toLowerCase();
      const vin = (vehicle.chassisNumber || vehicle.vin)?.trim().toLowerCase();
      const existing = (plate && byPlate[plate]) || (vin && byVin[vin]);

      if (existing) {
        const { error: updateError } = await supabase
          .from('vehicles')
          .update(vehicleData)
          .eq('id', existing.id);

        if (updateError) {
          console.error(`  FAILED ${vehicle.plateNumber}: ${updateError.message}`);
          failed++;
        } else {
          console.log(`  Backfilled external_id for ${vehicle.plateNumber} (${externalId})`);
          updated++;
          // Update local map so further iterations don't re-match
          if (plate) byPlate[plate] = { ...existing, external_id: externalId };
          if (vin) byVin[vin] = { ...existing, external_id: externalId };
        }
      } else {
        console.error(`  FAILED ${vehicle.plateNumber}: ${upsertError.message}`);
        failed++;
      }
    }

    console.log(`\n✓ Inserted: ${inserted} | Updated: ${updated} | Failed: ${failed}`);

    // Final count
    const { count } = await supabase.from('vehicles').select('*', { count: 'exact', head: true });
    console.log(`Total vehicles in DB: ${count}`);

    // Status distribution
    for (const s of ['available', 'in_use', 'maintenance', 'retired']) {
      const { count: c } = await supabase.from('vehicles').select('*', { count: 'exact', head: true }).eq('status', s);
      if (c) console.log(`  ${s}: ${c}`);
    }

  } catch (err) {
    console.error('Error:', err.message);
    if (err.response) console.error('API:', JSON.stringify(err.response.data).slice(0, 300));
  }
}

run();
