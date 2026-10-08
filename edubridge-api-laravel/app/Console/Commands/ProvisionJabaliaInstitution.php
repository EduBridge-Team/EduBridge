<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ProvisionJabaliaInstitution extends Command
{
    protected $signature = 'institutions:provision-jabalia {--domain=jabalia.edubridge.win}';

    protected $description = 'Create or update the Jabalia Rehabilitation Society EduBridge tenant.';

    public function handle(): int
    {
        $domain = strtolower(trim((string) $this->option('domain')));
        if (!preg_match('/^(?:[a-z0-9-]+\.)+edubridge\.win$/', $domain)) {
            $this->error('Domain must be an edubridge.win subdomain.');
            return self::FAILURE;
        }

        $settings = [
            'display_name' => 'جمعية جباليا للتأهيل',
            'login_title' => 'النظام الإلكتروني الذكي لإدارة المدرسة والتعليم البصري',
            'login_subtitle' => 'بدعم من منصة EduBridge',
            'locale' => 'ar',
            'features' => [
                'school_management' => true,
                'attendance' => true,
                'timetable' => true,
                'noor' => true,
                'sign_language' => true,
                'parent_bridge' => true,
            ],
        ];

        $existing = DB::table('organizations')->where('slug', 'jabalia')->first();
        $values = [
            'name' => 'جمعية جباليا للتأهيل',
            'domain' => $domain,
            'settings' => json_encode($settings, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'is_active' => true,
            'updated_at' => now(),
        ];

        if ($existing) {
            DB::table('organizations')->where('id', $existing->id)->update($values);
            $organizationId = $existing->id;
            $action = 'updated';
        } else {
            $organizationId = DB::table('organizations')->insertGetId([
                'name' => 'جمعية جباليا للتأهيل',
                'slug' => 'jabalia',
                'domain' => $domain,
                'settings' => json_encode($settings, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $action = 'created';
        }

        $this->info("Jabalia tenant {$action} successfully (organization_id={$organizationId}, domain={$domain}).");
        $this->line('No school or user accounts were created; those require confirmed operational data from the organization.');

        return self::SUCCESS;
    }
}
