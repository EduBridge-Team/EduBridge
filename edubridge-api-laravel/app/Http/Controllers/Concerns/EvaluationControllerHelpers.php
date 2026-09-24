<?php

namespace App\Http\Controllers\Concerns;

trait EvaluationControllerHelpers
{
    private function decode($evaluation)
    {
        if ($evaluation && isset($evaluation->teaching_methods) && is_string($evaluation->teaching_methods)) {
            $evaluation->teaching_methods = json_decode($evaluation->teaching_methods, true);
        }

        return $evaluation;
    }
}
