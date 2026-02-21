import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://fovrwhpndmrvnjdtzjxr.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvdnJ3aHBuZG1ydm5qZHR6anhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkxNTEyMTEsImV4cCI6MjA4NDcyNzIxMX0.E3NQBHtaWh9kA2jDDTgfes6PfrHpdSNuRQeX2gzkF70",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true
        )
    )
)
