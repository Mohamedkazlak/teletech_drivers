<?php

declare(strict_types=1);

return [
    'scheduled_in_past' => 'The scheduled time must be in the future.',
    'egyptian_car_plate' => 'Enter an Egyptian car plate with letters and numbers, for example ط ع ب 9295.',
    'phone_invalid' => 'Enter a valid phone number.',
    'attendance_invalid_qr' => 'This QR code is not the headquarters attendance code.',
    'attendance_mock_location' => 'A mocked location cannot be used to record attendance.',
    'attendance_low_accuracy' => 'The GPS reading is not accurate enough. Move closer to a window and try again.',
    'attendance_outside_radius' => 'You are :distance m from headquarters. You must be within :radius m.',
    'attendance_already_checked_in' => 'You already checked in today.',
    'attendance_not_checked_in' => 'Check in before you check out.',
    'attendance_already_checked_out' => 'You already checked out today.',
    'attendance_active_trip' => 'Finish the active trip before you check out.',
    'attendance_future_date' => 'Attendance cannot be adjusted for a future day.',
    'attendance_work_date_mismatch' => 'The check-in time must fall on the selected work day in Africa/Cairo.',
    'attendance_checkout_before_checkin' => 'Check-out must be at or after check-in.',
];
