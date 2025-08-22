// supabaseClient.js
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://gjwcskzeqqvomcuukytq.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdqd2Nza3plcXF2b21jdXVreXRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwOTg2NDMsImV4cCI6MjA2NjY3NDY0M30.voX24urUan0Hv4fb4-xUrcrOrGv_boHjIu42musT3KA';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
