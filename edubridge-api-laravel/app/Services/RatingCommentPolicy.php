<?php

namespace App\Services;

class RatingCommentPolicy
{
    public static function isAbusive(string $comment): bool
    {
        // Match whole words, ignoring Arabic vowel marks and tatweel.
        $normalized = preg_replace('/[\x{0640}\x{064B}-\x{065F}\x{0670}]/u', '', mb_strtolower($comment));
        $words = preg_split('/[^\p{L}\p{N}]+/u', $normalized, -1, PREG_SPLIT_NO_EMPTY);
        foreach (config('ratings.blocked_words', []) as $blocked) {
            if (in_array(mb_strtolower($blocked), $words, true)) {
                return true;
            }
        }

        return false;
    }
}
