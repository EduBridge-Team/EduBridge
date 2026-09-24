<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            throw new RuntimeException('EduBridge fresh migrations require PostgreSQL.');
        }

        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'password_hash')) {
                $table->string('password_hash')->nullable();
            }
            if (!Schema::hasColumn('users', 'role')) {
                $table->string('role', 20)->nullable();
            }
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone', 20)->nullable();
            }
            if (!Schema::hasColumn('users', 'specialty')) {
                $table->string('specialty', 32)->nullable();
            }
            if (!Schema::hasColumn('users', 'avatar_url')) {
                $table->text('avatar_url')->nullable();
            }
        });

        Schema::create('disability_types', function (Blueprint $table) {
            $table->id();
            $table->string('name', 80)->unique();
            $table->text('description')->nullable();
        });

        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('contact', 150)->nullable();
            $table->string('address', 255)->nullable();
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->date('birth_date')->nullable();
            $table->integer('age')->nullable();
            $table->string('gender', 10)->nullable();
            $table->foreignId('disability_type_id')->nullable()->constrained('disability_types')->restrictOnDelete();
            $table->string('disability_type', 120)->nullable();
            $table->text('disability_description')->nullable();
            $table->text('medical_history')->nullable();
            $table->text('psychologist_notes')->nullable();
            $table->text('special_needs')->nullable();
            $table->string('preferred_learning_style', 120)->nullable();
            $table->json('strengths')->nullable();
            $table->json('challenges')->nullable();
            $table->string('status', 20)->default('pending');
            $table->foreignId('assigned_teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('organization_id')->nullable()->constrained('organizations')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->string('child_national_id', 30)->nullable();
            $table->string('guardian_national_id', 30)->nullable();
            $table->string('guardian_id_document_url', 255)->nullable();
            $table->string('kinship_document_url', 255)->nullable();
            $table->string('doc_verification_status', 20)->default('pending');
            $table->text('doc_verification_note')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('disability_type_id');
            $table->index('assigned_teacher_id');
            $table->index('child_national_id');
        });

        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('evaluator_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('evaluation_type', 60)->nullable();
            $table->text('cognitive_assessment')->nullable();
            $table->text('motor_assessment')->nullable();
            $table->text('emotional_assessment')->nullable();
            $table->text('social_assessment')->nullable();
            $table->text('recommendations')->nullable();
            $table->text('educational_plan')->nullable();
            $table->json('teaching_methods')->nullable();
            $table->foreignId('assigned_teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->index('child_id');
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('parent_id')->constrained('users')->cascadeOnDelete();
            $table->primary(['child_id', 'parent_id']);
        });

        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title', 150);
            $table->text('content')->nullable();
            $table->foreignId('disability_type_id')->nullable()->constrained('disability_types')->nullOnDelete();
            $table->foreignId('teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('target_type', 32)->default('everyone');
            $table->json('target_child_ids')->nullable();
            $table->text('audio_description')->nullable();
            $table->string('education_level', 60)->nullable();
            $table->string('curriculum_status', 20)->default('pending');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('review_note')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('disability_type_id');
            $table->index('curriculum_status');
        });

        Schema::create('progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('lesson_id')->constrained('lessons')->cascadeOnDelete();
            $table->string('status', 15)->default('not_started');
            $table->integer('score')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->unique(['child_id', 'lesson_id']);
            $table->index('child_id');
        });

        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lesson_id')->constrained('lessons')->cascadeOnDelete();
            $table->string('type', 20);
            $table->string('url', 2048);
        });

        Schema::create('learning_support_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('parent_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('specialist_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('reason', 160);
            $table->text('description')->nullable();
            $table->string('urgency', 16)->default('medium');
            $table->string('status', 20)->default('pending');
            $table->timestamp('scheduled_at')->nullable();
            $table->text('meeting_link')->nullable();
            $table->text('specialist_notes')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();
            $table->index('child_id');
            $table->index('parent_id');
            $table->index('specialist_id');
            $table->index('status');
            $table->index('created_at');
        });

        DB::statement("CREATE UNIQUE INDEX uq_learning_support_requests_open_parent_child ON learning_support_requests(parent_id, child_id) WHERE status IN ('pending','scheduled')");

        Schema::create('sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('specialist_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('learning_support_request_id')->nullable()->constrained('learning_support_requests')->nullOnDelete();
            $table->timestamp('scheduled_at');
            $table->string('status', 15)->default('scheduled');
            $table->string('type', 32)->default('followUp');
            $table->integer('duration_minutes')->default(45);
            $table->timestamp('completed_at')->nullable();
            $table->text('notes')->nullable();
            $table->text('goals')->nullable();
            $table->text('recommendations')->nullable();
            $table->json('tags')->default('[]');
            $table->text('meeting_link')->nullable();
            $table->index('child_id');
        });

        DB::statement('CREATE UNIQUE INDEX uq_sessions_learning_support_request ON sessions(learning_support_request_id) WHERE learning_support_request_id IS NOT NULL');

        Schema::create('notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->text('content');
            $table->timestamp('created_at')->useCurrent();
            $table->index('child_id');
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 150)->nullable();
            $table->string('message', 255);
            $table->string('type', 40)->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('created_at')->useCurrent();
            $table->index('user_id');
        });

        Schema::create('certificates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 150);
            $table->string('url', 255);
            $table->string('status', 20)->default('pending');
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index('user_id');
        });

        Schema::create('lesson_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lesson_id')->constrained('lessons')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->integer('stars');
            $table->text('comment')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['lesson_id', 'user_id']);
            $table->index('lesson_id');
        });

        Schema::create('support_tickets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('category', 20)->default('support');
            $table->string('subject', 150);
            $table->text('message');
            $table->string('status', 20)->default('open');
            $table->text('admin_reply')->nullable();
            $table->timestamps();
            $table->index('user_id');
            $table->index('status');
        });

        Schema::create('consultations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('requester_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('specialist_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->string('status', 20)->default('open');
            $table->timestamp('created_at')->useCurrent();
            $table->index('child_id');
            $table->index('specialist_id');
        });

        Schema::create('consultation_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('consultation_id')->constrained('consultations')->cascadeOnDelete();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->text('content');
            $table->timestamp('created_at')->useCurrent();
            $table->index('consultation_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->cascadeOnDelete();
            $table->string('specialty', 32);
            $table->timestamp('assigned_at')->useCurrent();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['child_id', 'specialist_id', 'specialty']);
            $table->index('child_id');
            $table->index('specialist_id');
        });

        Schema::create('specialist_suggestions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('suggested_by')->constrained('users')->cascadeOnDelete();
            $table->string('specialty', 32);
            $table->text('reason');
            $table->string('status', 20)->default('pending');
            $table->text('rejection_reason')->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();
            $table->index(['specialist_id', 'status']);
            $table->index('child_id');
        });

        DB::statement("CREATE UNIQUE INDEX uq_specialist_suggestions_pending ON specialist_suggestions(child_id, specialist_id, specialty) WHERE status = 'pending'");

        Schema::create('homeworks', function (Blueprint $table) {
            $table->id();
            $table->string('title', 180);
            $table->text('description');
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->string('subject', 120)->nullable();
            $table->timestamp('due_date');
            $table->json('assigned_child_ids')->default('[]');
            $table->json('attachment_urls')->default('[]');
            $table->timestamps();
            $table->index('teacher_id');
            $table->index('due_date');
        });

        Schema::create('homework_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('homework_id')->constrained('homeworks')->cascadeOnDelete();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->text('text_answer')->nullable();
            $table->text('file_url')->nullable();
            $table->json('file_urls')->default('[]');
            $table->integer('grade')->nullable();
            $table->text('feedback')->nullable();
            $table->boolean('is_late')->default(false);
            $table->foreignId('graded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('graded_at')->nullable();
            $table->timestamp('submitted_at')->useCurrent();
            $table->timestamps();
            $table->unique(['homework_id', 'child_id']);
            $table->index('child_id');
        });

        Schema::create('weekly_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('week_start');
            $table->date('week_end');
            $table->integer('lessons_completed')->default(0);
            $table->decimal('progress_percentage', 5, 2)->default(0);
            $table->text('teacher_notes')->nullable();
            $table->text('specialist_notes')->nullable();
            $table->text('parent_notes')->nullable();
            $table->json('achievements')->default('[]');
            $table->json('concerns')->default('[]');
            $table->integer('learning_support_meetings_scheduled')->default(0);
            $table->integer('learning_support_meetings_attended')->default(0);
            $table->timestamp('generated_at')->useCurrent();
            $table->timestamps();
            $table->unique(['child_id', 'week_start']);
            $table->index(['child_id', 'week_start']);
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->string('subject', 120)->nullable();
            $table->timestamp('assigned_at')->useCurrent();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['child_id', 'teacher_id']);
            $table->index('child_id');
            $table->index('teacher_id');
        });

        Schema::create('case_discussions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->string('topic', 180);
            $table->text('description')->nullable();
            $table->string('status', 20)->default('open');
            $table->foreignId('created_by_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
            $table->index('child_id');
        });

        Schema::create('case_discussion_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('discussion_id')->constrained('case_discussions')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['discussion_id', 'user_id']);
            $table->index('user_id');
        });

        Schema::create('case_discussion_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('discussion_id')->constrained('case_discussions')->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->text('content');
            $table->string('type', 20)->default('text');
            $table->json('attachments')->default('[]');
            $table->timestamp('created_at')->useCurrent();
            $table->index(['discussion_id', 'created_at']);
        });

        Schema::create('ministry_approvals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('evaluation_id')->nullable()->constrained('evaluations')->nullOnDelete();
            $table->foreignId('submitted_by')->constrained('users')->cascadeOnDelete();
            $table->foreignId('teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('educational_plan');
            $table->text('cognitive_assessment')->nullable();
            $table->text('motor_assessment')->nullable();
            $table->text('emotional_assessment')->nullable();
            $table->text('social_assessment')->nullable();
            $table->text('recommendations')->nullable();
            $table->json('teaching_methods')->default('[]');
            $table->string('status', 20)->default('pending');
            $table->text('review_reason')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->index('status');
            $table->index('child_id');
        });

        Schema::create('plan_evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('plan_id');
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('evaluator_id')->constrained('users')->cascadeOnDelete();
            $table->boolean('is_plan_appropriate');
            $table->text('notes_for_teacher')->nullable();
            $table->json('recommended_changes')->default('[]');
            $table->timestamps();
            $table->unique(['plan_id', 'child_id', 'evaluator_id']);
            $table->index('child_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('national_id', 30)->nullable();
            $table->string('id_document_url', 255)->nullable();
            $table->string('verification_status', 20)->default('pending');
            $table->text('verification_note')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->index('national_id');
            $table->index('verification_status');
        });
    }

    public function down(): void
    {
        foreach ([
            'plan_evaluations',
            'ministry_approvals',
            'case_discussion_messages',
            'case_discussion_participants',
            'case_discussions',
            'child_teacher',
            'weekly_reports',
            'homework_submissions',
            'homeworks',
            'specialist_suggestions',
            'child_specialist',
            'consultation_notes',
            'consultations',
            'support_tickets',
            'lesson_ratings',
            'certificates',
            'notifications',
            'notes',
            'sessions',
            'learning_support_requests',
            'media',
            'progress',
            'lessons',
            'child_parent',
            'evaluations',
            'children',
            'organizations',
            'disability_types',
        ] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
