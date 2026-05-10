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

async function fetchRiders(kycParam) {
  const res = await walimApi.get(`/api/account/users?KYC=${encodeURIComponent(kycParam)}&UserRoles=Riders&EmployeeType=all&RiderAppName=all&takeRecords=all`);
  return res.data.data || res.data || [];
}

async function run() {
  try {
    await authenticate();

    // KYC=1 returns Active_Completed riders (confirmed via probe)
    console.log('Fetching Active_Completed riders (KYC=1)...');
    const activeCompletedRiders = await fetchRiders('1');
    console.log(`  → ${activeCompletedRiders.length} Active_Completed riders`);
    const activeCompletedIds = new Set(
      activeCompletedRiders.map(item => (item.user || item).id?.toString()).filter(Boolean)
    );

    // Fetch all riders and update statuses
    console.log('\nFetching all riders for status update...');
    const allRiders = await fetchRiders('all');
    console.log(`Total: ${allRiders.length} riders\n`);

    let updated = 0, failed = 0;

    for (const item of allRiders) {
      const user = item.user || item;
      if (!user?.id) continue;

      const externalId = user.id.toString();
      const isActive = user.employeesVM?.isActive ?? true;

      let newStatus;
      if (activeCompletedIds.has(externalId)) {
        newStatus = 'Active_Completed';
      } else if (isActive) {
        newStatus = 'Active_Pending';
      } else {
        newStatus = 'inactive';
      }

      const { error } = await supabase
        .from('profiles')
        .update({ status: newStatus })
        .eq('external_id', externalId);

      if (error) { failed++; }
      else { updated++; }
    }

    console.log(`✓ Updated: ${updated} | Failed: ${failed}\n`);

    // Verify final counts
    const statusValues = ['Active_Completed', 'Active_Pending', 'inactive', 'active'];
    console.log('Final status distribution:');
    for (const s of statusValues) {
      const { count } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('status', s);
      if (count) console.log(`  ${s}: ${count}`);
    }

  } catch (err) {
    console.error('Error:', err.message);
    if (err.response) console.error('API:', JSON.stringify(err.response.data).slice(0, 300));
  }
}

run();
