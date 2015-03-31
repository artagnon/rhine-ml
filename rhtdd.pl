use IO::Select qw//;
use IPC::Open3 qw/open3/;
use Symbol qw/gensym/;

my $dirToWatch=shift;
`which fswatch` || die "fswatch not found";
print "Watching $dirToWatch\n";
my $pid = open3(my $in, my $out, my $err = gensym(),
		"fswatch -r $dirToWatch") || die "Could not open3";
print "Ready...\n";

my $sel = new IO::Select;
$sel->add($out, $err);
while (my @ready = $sel->can_read) {
  foreach my $handle (@ready) {
    my $bytes_read = sysread($handle, my $buf='', 1024);
    if (not /.#/ =~ $buf) {
      print $buf;
      print `make check`;
    }
  }
}
