// ============================================================
// CHURCH OF CREATIONSHIP — DATA LAYER (Supabase)
// ============================================================

var SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';
var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4c2JxcHRxZ3JleXd1dGJmYnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MDgyNjUsImV4cCI6MjA5MjE4NDI2NX0.bCle-Yg_fYj8V5HeZtHiXYxEqzufeS5KFWBssSeGKOM';

// Initialize Supabase client
// Note: The UMD CDN bundle creates a global `supabase` variable.
// We use `_supabaseClient` to avoid shadowing.
var _supabaseClient;
try {
  var _sb = window.supabase || supabase;
  if (_sb && _sb.createClient) {
    _supabaseClient = _sb.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  } else {
    console.error('Supabase CDN not loaded. window.supabase:', window.supabase);
  }
} catch (e) {
  console.error('Supabase init error:', e);
}

// ============================================================
// PUBLIC API
// ============================================================

window.DB = {

  // --- People ---

  async addPerson(person) {
    const { data, error } = await _supabaseClient
      .from('people')
      .insert({
        name: person.name,
        email: person.email,
        phone: person.phone || ''
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async getPeople() {
    const { data, error } = await _supabaseClient
      .from('people')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async getPersonById(id) {
    const { data, error } = await _supabaseClient
      .from('people')
      .select('*')
      .eq('id', id)
      .single();
    if (error) return null;
    return data;
  },

  async findPersonByEmail(email) {
    const { data, error } = await _supabaseClient
      .from('people')
      .select('*')
      .ilike('email', email)
      .maybeSingle();
    if (error) return null;
    return data;
  },

  async updatePerson(id, updates) {
    const { data, error } = await _supabaseClient
      .from('people')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) return null;
    return data;
  },

  // --- Role Signups ---

  async addSignup(signup) {
    const { data, error } = await _supabaseClient
      .from('role_signups')
      .insert({
        person_id: signup.person_id,
        role_type: signup.role_type,
        status: 'pending',
        intake_data: signup.intake_data || {}
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async getSignups(filters = {}) {
    let query = _supabaseClient
      .from('role_signups')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (filters.role_type) {
      query = query.eq('role_type', filters.role_type);
    }
    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  },

  async getSignupById(id) {
    const { data, error } = await _supabaseClient
      .from('role_signups')
      .select('*')
      .eq('id', id)
      .single();
    if (error) return null;
    return data;
  },

  async updateSignup(id, updates) {
    const { data, error } = await _supabaseClient
      .from('role_signups')
      .update(updates)
      .eq('id', id)
      .select()
      .single();
    if (error) return null;
    return data;
  },

  // --- Sundays ---

  async getSundays(year, month) {
    let query = _supabaseClient
      .from('sundays')
      .select('*')
      .order('date', { ascending: true });
    
    if (year !== undefined && month !== undefined) {
      const startDate = `${year}-${String(month + 1).padStart(2, '0')}-01`;
      const endMonth = month + 2 > 12 ? 1 : month + 2;
      const endYear = month + 2 > 12 ? year + 1 : year;
      const endDate = `${endYear}-${String(endMonth).padStart(2, '0')}-01`;
      query = query.gte('date', startDate).lt('date', endDate);
    }
    
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  },

  async getSundayByDate(dateStr) {
    const { data, error } = await _supabaseClient
      .from('sundays')
      .select('*')
      .eq('date', dateStr)
      .maybeSingle();
    if (error) return null;
    return data;
  },

  async upsertSunday(sunday) {
    const { data, error } = await _supabaseClient
      .from('sundays')
      .upsert({
        date: sunday.date,
        status: sunday.status || 'open',
        teacher_signup_id: sunday.teacher_signup_id || null,
        space_holder_ids: sunday.space_holder_ids || [],
        title: sunday.title || '',
        description: sunday.description || '',
        recording_url: sunday.recording_url || '',
        notes: sunday.notes || '',
        themes: sunday.themes || []
      }, { onConflict: 'date' })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  // --- Stats ---

  async getStats() {
    const [signupsRes, peopleRes] = await Promise.all([
      _supabaseClient.from('role_signups').select('id, role_type, status'),
      _supabaseClient.from('people').select('id')
    ]);
    
    const signups = signupsRes.data || [];
    const people = peopleRes.data || [];
    
    return {
      total_signups: signups.length,
      pending: signups.filter(s => s.status === 'pending').length,
      approved: signups.filter(s => s.status === 'approved').length,
      declined: signups.filter(s => s.status === 'declined').length,
      by_role: {
        hold_space: signups.filter(s => s.role_type === 'hold_space').length,
        teach: signups.filter(s => s.role_type === 'teach').length,
        brain_trust: signups.filter(s => s.role_type === 'brain_trust').length
      },
      total_people: people.length
    };
  },

  // --- Export ---

  async exportAll() {
    const [people, signups, sundays, invitations] = await Promise.all([
      _supabaseClient.from('people').select('*'),
      _supabaseClient.from('role_signups').select('*'),
      _supabaseClient.from('sundays').select('*'),
      _supabaseClient.from('invitations').select('*')
    ]);
    
    return {
      people: people.data || [],
      signups: signups.data || [],
      sundays: sundays.data || [],
      invitations: invitations.data || [],
      exported_at: new Date().toISOString()
    };
  }
};
