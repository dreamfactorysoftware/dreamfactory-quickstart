#!/usr/bin/env php
<?php
/**
 * Skip the 1.7.7 Admin UI commercial-expiry guard in a quickstart binary.
 *
 * The guard treats license_key:false as defined and can send evaluation
 * builds to the expired-subscription page. The OPEN SOURCE engagement
 * banner is left unchanged.
 */

$root = $argv[1] ?? '/build/app';
$pattern = '/\(([A-Za-z_$][\w$]*)=>"OPEN SOURCE"===\1\.platform\?\.license\?'
    . '\(0,([A-Za-z_$][\w$]*)\.of\)\(!0\):void 0!==\1\.platform\?\.licenseKey\?/';
$replacement = '($1=>!0?(0,$2.of)(!0):void 0!==$1.platform?.licenseKey?';

$patched = 0;
$iterator = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)
);

foreach ($iterator as $file) {
    if (!$file->isFile() || !preg_match('/^main\..+\.js$/', $file->getFilename())) {
        continue;
    }

    $text = file_get_contents($file->getPathname());
    $updated = preg_replace($pattern, $replacement, $text, 1, $count);
    if ($count > 0) {
        file_put_contents($file->getPathname(), $updated);
        fwrite(STDERR, 'patched license guard in ' . $file->getPathname() . PHP_EOL);
        $patched += $count;
    }
}

if ($patched === 0) {
    fwrite(STDERR, "error: admin UI license-guard pattern not found in {$root}\n");
    exit(1);
}
