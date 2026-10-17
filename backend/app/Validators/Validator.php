<?php

namespace App\Validators;

use App\Services\Response;

class Validator {
    public static function validate(array $data, array $rules): array {
        $errors = [];
        $sanitized = [];

        foreach ($rules as $field => $fieldRules) {
            $value = $data[$field] ?? null;
            $ruleList = is_string($fieldRules) ? explode('|', $fieldRules) : $fieldRules;

            foreach ($ruleList as $rule) {
                if ($rule === 'required' && ($value === null || trim((string)$value) === '')) {
                    $errors[$field][] = "Field {$field} is required.";
                } elseif ($value !== null && $value !== '') {
                    if ($rule === 'email' && !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                        $errors[$field][] = "Field {$field} must be a valid email address.";
                    } elseif (strpos($rule, 'min:') === 0) {
                        $min = (int)substr($rule, 4);
                        if (strlen((string)$value) < $min) {
                            $errors[$field][] = "Field {$field} must be at least {$min} characters.";
                        }
                    } elseif (strpos($rule, 'max:') === 0) {
                        $max = (int)substr($rule, 4);
                        if (strlen((string)$value) > $max) {
                            $errors[$field][] = "Field {$field} must not exceed {$max} characters.";
                        }
                    }
                }
            }

            $sanitized[$field] = is_string($value) ? trim(htmlspecialchars($value, ENT_QUOTES, 'UTF-8')) : $value;
        }

        if (!empty($errors)) {
            Response::error('Validation failed', 422, $errors);
        }

        return $sanitized;
    }
}
