const { createClient } = require('@supabase/supabase-js');
const ws = require('ws');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
  realtime: { transport: ws }
});

async function run() {
  console.log('Fetching roles...');
  const { data: roles, error: rolesError } = await supabase.from('roles').select('id, name');
  if (rolesError) {
    console.error('Failed to fetch roles:', rolesError.message);
    return;
  }

  const riderRole = roles.find(r => r.name === 'Rider');
  if (!riderRole) {
    console.error('Rider role not found');
    return;
  }

  console.log('Fetching riders...');
  const { data: riders, error: ridersError } = await supabase
    .from('profiles')
    .select('id, full_name')
    .eq('role_id', riderRole.id);

  if (ridersError) {
    console.error('Failed to fetch riders:', ridersError.message);
    return;
  }

  console.log(`Found ${riders.length} riders.`);

  const cities = [
    { name: 'Jeddah', lat: 21.4858, lng: 39.1925 },
    { name: 'Taif', lat: 21.2854, lng: 40.4094 }
  ];

  let updated = 0;
  for (const rider of riders) {
    // Pick a random city
    const city = cities[Math.floor(Math.random() * cities.length)];
    // Generate small offset for realism
    const latOffset = (Math.random() - 0.5) * 0.15;
    const lngOffset = (Math.random() - 0.5) * 0.15;

    const { error } = await supabase.from('profiles').update({
      last_lat: city.lat + latOffset,
      last_lng: city.lng + lngOffset,
      last_location_update: new Date().toISOString()
    }).eq('id', rider.id);

    if (error) {
      console.error(`Failed to update ${rider.full_name}:`, error.message);
    } else {
      updated++;
    }
  }

  console.log(`Successfully simulated locations for ${updated}/${riders.length} riders.`);
}

run();
