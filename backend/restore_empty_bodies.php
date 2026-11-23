<?php

declare(strict_types=1);

$root = dirname(__FILE__);
$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root));
$updated = 0;

foreach ($iterator as $file) {
    if (! $file->isFile() || $file->getExtension() !== 'php') {
        continue;
    }

    $path = $file->getPathname();
    if (str_contains($path, DIRECTORY_SEPARATOR.'vendor'.DIRECTORY_SEPARATOR)) {
        continue;
    }

    $contents = file_get_contents($path);
    if ($contents === false || ! str_contains($contents, '    ) {
    }')) {
        continue;
    }

    $eol = str_contains($contents, "\r\n") ? "\r\n" : "\n";
    $new = str_replace('    ) {
    }', '    ) {'.$eol.'    }', $contents);
    if ($new !== $contents) {
        file_put_contents($path, $new);
        $updated++;
        echo $path, PHP_EOL;
    }
}

echo "updated {$updated} files", PHP_EOL;
