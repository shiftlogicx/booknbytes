import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://zmbutpslrmbrqncuiowr.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptYnV0cHNscm1icnFuY3Vpb3dyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMjM1MDUsImV4cCI6MjEwODY5OTUwNX0.lViAWCu7qNUdpgWa-3vjguZ0KS32IfB0TyLKJeFsIc8';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptYnV0cHNscm1icnFuY3Vpb3dyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MzEyMzUwNSwiZXhwIjoyMTA4Njk5NTA1fQ.8BI7ssPAeY2CAtca1F3tCfHC1w1wt-rd4ssYM59sGkM';

// Standard client for browser / public operations
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});

// Admin client with service_role key to bypass RLS for administrative management
export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

export const EDGE_FUNCTIONS = {
  signupOwner: `${supabaseUrl}/functions/v1/signup-owner`,
  activateRestaurant: `${supabaseUrl}/functions/v1/activate-restaurant`,
  updateManagerPassword: `${supabaseUrl}/functions/v1/update-manager-password`,
};
