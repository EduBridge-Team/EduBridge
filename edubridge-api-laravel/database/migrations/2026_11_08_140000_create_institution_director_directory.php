<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('institution_director_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->string('name', 150);
            $table->string('email', 190);
            $table->string('phone', 30)->default('');
            $table->string('qualification', 255)->default('');
            $table->unsignedTinyInteger('experience_years')->default(0);
            // A profile cannot itself create a login. A separately verified,
            // dedicated school_director identity can be linked later.
            $table->foreignId('identity_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['school_id', 'id']);
        });
        Schema::create('institution_director_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('director_id')->constrained('institution_director_profiles')->restrictOnDelete();
            $table->date('starts_on');
            $table->date('ended_on')->nullable();
            $table->foreignId('appointed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('ended_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['school_id', 'id']);
        });

        // Import existing operational appointments without changing their
        // owners or status. History is visible on first directory read.
        $legacy = DB::table('school_management_assignments as a')
            ->join('users as u', 'u.id', '=', 'a.user_id')
            ->where('a.role', 'director')
            ->orderBy('a.id')
            ->select('a.*', 'u.name as director_name', 'u.email as director_email', 'u.role as director_role')
            ->cursor();

        foreach ($legacy as $appointment) {
            $email = mb_strtolower(trim((string) $appointment->director_email));
            $name = trim((string) $appointment->director_name);
            if ($email === '' || $name === '' || empty($appointment->starts_at)) {
                throw new RuntimeException('Legacy director history has missing identity or appointment data');
            }
            $existing = DB::table('institution_director_profiles')
                ->where('school_id', $appointment->school_id)
                ->whereRaw('LOWER(email) = ?', [$email])->first();
            if ($existing) {
                $profileId = $existing->id;
            } else {
                $profileId = DB::table('institution_director_profiles')->insertGetId([
                    'school_id' => $appointment->school_id,
                    'name' => $name, 'email' => $email, 'phone' => '',
                    'qualification' => '', 'experience_years' => 0,
                    'identity_user_id' => $appointment->director_role === 'school_director'
                        ? $appointment->user_id : null,
                    'created_by' => $appointment->appointed_by,
                    'updated_by' => $appointment->appointed_by,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
            }
            DB::table('institution_director_assignments')->insert([
                'school_id' => $appointment->school_id,
                'director_id' => $profileId,
                'starts_on' => substr((string) $appointment->starts_at, 0, 10),
                'ended_on' => $appointment->ends_at === null ? null : substr((string) $appointment->ends_at, 0, 10),
                'appointed_by' => $appointment->appointed_by, 'ended_by' => null,
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }

        // PostgreSQL/SQLite: case-insensitive per-school email and one current
        // directory assignment. Index creation fails closed on dirty legacy data.
        DB::statement('CREATE UNIQUE INDEX institution_director_school_email_unique
            ON institution_director_profiles (school_id, LOWER(email))');
        DB::statement('CREATE UNIQUE INDEX institution_director_one_current_unique
            ON institution_director_assignments (school_id) WHERE ended_on IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('institution_director_assignments');
        Schema::dropIfExists('institution_director_profiles');
    }
};
