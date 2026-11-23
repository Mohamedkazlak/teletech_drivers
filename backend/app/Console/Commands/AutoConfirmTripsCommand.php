<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Application\Trips\Actions\AutoConfirmStaleTripsAction;
use DateTimeImmutable;
use Illuminate\Console\Command;

final class AutoConfirmTripsCommand extends Command
{
    protected $signature = 'trips:auto-confirm';

    protected $description = 'Mark trips awaiting confirmation for 24 hours as unconfirmed';

    public function handle(AutoConfirmStaleTripsAction $action): int
    {
        $updated = $action->execute(DateTimeImmutable::createFromInterface(now()));

        $this->info('Marked '.$updated.' trip(s) as unconfirmed.');

        return self::SUCCESS;
    }
}
