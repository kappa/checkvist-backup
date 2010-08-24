#! /usr/bin/perl
use uni::perl;

use WebService::Simple;
use Archive::Tar;
use Encode;
use Getopt::Long;

my ($login, $remotekey, $output_dir);

GetOptions('login=s' => \$login, 'remotekey=s' => \$remotekey,
    'output=s' => \$output_dir);

unless ($login && $remotekey) {
    die "Usage: $0 --login <login> --remotekey <remotekey> [--output <output dir>]\n\nObtain your remote key on your Checkvist profile page\n";
}

$output_dir //= '.';

my $chv = WebService::Simple->new(
    base_url    => 'http://checkvist.com/',
    response_parser => 'JSON',
);
$chv->credentials('checkvist.com:80', 'Application', $login,
    $remotekey);

my $lists_res = $chv->get('checklists.json');

my $tar = Archive::Tar->new();
for my $list (@{$lists_res->parse_response}) {
    say "Fetching $list->{name}";
    my $data = $chv->get("checklists/$list->{id}.opml", {
            export_status   => 'true',
            export_notes    => 'true',
            export_details  => 'true',
            export_color    => 'true',
        })->content;

    $tar->add_data(encode('utf-8', "$list->{name}.opml"),
        encode('utf-8', $data));
}

$tar->add_data(encode('utf-8', 'content.json'),
    encode('utf-8', $lists_res->content));

$tar->write("$output_dir/checkvist.tar.bz2", COMPRESS_BZIP);
