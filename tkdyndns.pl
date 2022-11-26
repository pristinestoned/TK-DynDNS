#!/usr/bin/perl -w


#Author is not held responsible for any damages by this script. 
#Feel free to redistribute and modify the script.
#
#
# Author: brian2004[at] hotmail[dot] com
#
# DynDNS Utility v1.0
# Feel free to modify and redistribute under GNU
# Obtain IP address from http://checkip.dyndns.org

$^W++;                            # Turn on debug warnings
use strict;                       # Strict Variables!
use IO::Socket;                   # Sock support
use MIME::Base64;                 # Base64 encoding support
use Data::Dumper;                 # Data Dumper

use Tk;
use Tk::Dialog;
use Tk::Entry;
use Tk::Label;
use Tk::Scrollbar;
use Tk::Text;
use Tk::Menu;
use Tk::Frame;
use Tk::DialogBox;
use Tk::Menubutton;
use Tk::Button;
use Tk::Radiobutton;
use Tk::Toplevel;
use Tk::Optionmenu;

my $version = "1.0";
my $lupdate = "April/11/2004";
my $reported_ip = "0.0.0.0";
my $remote_host = "checkip.dyndns.org";
my $remote_port = "80";
my $remote_url = "/";
my @socket_buffer = ();
my $tmpdata = "";
my $username = "";
my $password = "";
my $dyntype = "statdns";
my $g_dyntype = "statdns";   
my $dynhost = "yourhost.ath.cx";
my $dynstate = "Idle...";
my $encoded;
my $decoded;

my $h_type = {'Dynamic DNS'    => 'dyndns',
              'Static DNS'     => 'statdns',
              'Custom DNS'     => 'custom'};
my @host_type = keys %$h_type;

# Create and Display GUI
my $mw = MainWindow->new();

$mw->title ("Tk-DYNDNS IP Manager");
$mw->geometry('+500+300');
$mw->configure(-menu       => my $menubar = $mw->Menu);

# File Menu
my $file = $menubar->cascade(-label     => '~File',
                             -tearoff   => 0,
);

$file->command(
    -label       => "Close",
    -accelerator => 'Ctrl-w',
    -underline   => 0,
    -command     => \&exit,
);

# Help Menu
my $help = $menubar->cascade(-label     => '~Help',
                             -tearoff   => 0,
);

$help->command(
   -label        => "About",
   -command      => \&mnabout,
);

my $frm1 = $mw->Frame(
     -relief       => 'groove',
     -borderwidth  => 2,
     -background   => 'black',
)
     ->pack(
     -side        => 'top',
     -fill        => 'x'
);

my $lbl1 = $mw->Label(
     -text         => "Tk-DYNDNS Client. VER: $version",
     -font         => "-family Elephant -weight normal",
)
     ->pack(
     -side         => 'top'
);
my $frm2 = $mw->Frame(
     -relief       => 'groove',
     -borderwidth  => 2,
     -background   => 'gray',
)
     ->pack(
     -side        => 'top',
     -padx        => 120,
     -pady        => 10,
     -fill        =>'x'
);
my $lbl2 = $mw->Label(
     -text         => "Detected IP address:",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw'
);
 
my $txt1 = $mw->Entry(
     -textvariable => \$reported_ip,
     -background   => 'gray',
     -foreground   => 'black',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne'
);

my $lbl3 = $mw->Label(
     -text         => "Your DNS host type:   ",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw',
);

my $opt1 = $mw->Optionmenu(
     -options      => \@host_type,
     -variable     => \$dyntype,
     -background   => 'gray',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne'
);

my $lbl4 = $mw->Label(
     -text         => "Your DNS host name:   ",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw',
);

my $txt2 = $mw->Entry(
     -textvariable => \$dynhost,
     -background   => 'gray',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne'
);

my $lbl5 = $mw->Label(
     -text         => "Your DNS username:  ",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw',
);
my $txt3 = $mw->Entry(
     -textvariable => \$username,
     -background   => 'gray',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne'
);

my $lbl6 = $mw->Label(
     -text         => "Your DNS password: ",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw',
);

my $txt4 = $mw->Entry(
     -textvariable => \$password,
     -show         => "*",
     -background   => 'gray',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne'
);

my $lbl7 = $mw->Label(
     -text         => "Program status: ",
)
     ->pack(
     -side         => 'top',
     -anchor       => 'nw',
);

my $txt7 = $mw->Entry(
     -textvariable => \$dynstate,
     -background   => 'grey',
)
     ->pack(
     -side         => 'top',
     -anchor       => 'ne',
);

my $frm3 = $mw->Frame(
     -relief       => 'groove',
     -borderwidth  => 2,
     -background   => 'black',
)
     ->pack(
     -side        => 'top',
     -padx        => 120,
     -pady        => 10,
     -fill        => 'x'
);

my $btn1 = $mw->Button(
     -text         => "Update",
     -command      => sub { &update_ip }
)
     ->pack(
     -side         => 'left',
     -anchor       => 'nw',
);

my $btn2 = $mw->Button(
     -text         => "Done",
     -command      => sub { exit }
)
     ->pack(
     -side         => 'left',
     -anchor       => 'ne',
);

# Focus in the username box
$txt3->focus;

my $socket = new IO::Socket::INET (PeerAddr => $remote_host,
                                PeerPort => $remote_port,
                                Proto    => "tcp",
                                Type     => SOCK_STREAM)
    or die "Can't connect to $remote_host:$remote_port : $!\n";

print $socket "GET $remote_url HTTP/1.0\n";
print $socket "Accept: */*\n";
print $socket "User-Agent: Tk-DynIP ($version)\n";
print $socket "Connection: Keep-Alive\n";
print $socket "\r\n\r\n";
@socket_buffer = <$socket>;

foreach (@socket_buffer) {
 #print $_."\n";
 $reported_ip = $_;
 chop ($reported_ip);
 if ($reported_ip =~ /[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/) {

  # Debug
  # print "\nIP address detected by DynDNS Server: $&\n";

  $reported_ip = $&;
 }
}
# Initiate Main Loop where the Loop.
MainLoop();

# Subroutine for about operation.
sub mnabout{
  my $dw = $mw->Dialog(
              -title     => 'About IP Manager',
              -bitmap    => 'info',
              -buttons   => ["OK",],
              -text      => "Tk-DYNDNS IP Manager $version\n".
                            "Brian Ponnampalam\n".
                            " ".
                            "Last Updated: $lupdate\n",
  );
  $dw->Show;
}

# Subroutine for Update operation.
sub update_ip{
   # Debug
   # print "Update Loop\n";
   # print "Selected: ".$dyntype."\=".$h_type->{"$dyntype"}."\n";
   # print $dyntype;

   $dynstate = "Sending...";
   $g_dyntype = $h_type->{"$dyntype"};

   $encoded = encode_base64("$username:$password");
   #$decoded = decode_base64($encoded);
  
   # Debug
   # print "Encoded: ".$encoded."\n";
   # print "Decoded: ".$decoded."\n";
 
   $remote_host = "members.dyndns.org";
   $remote_url  = "/nic/update\?system\=$g_dyntype\&hostname\=$dynhost\&".
                  "myip\=$reported_ip\&wildcard\=OFF\&mx\=$dynhost\&".
                  "backmx\=YES&offline\=NO";

   # Debug
   # print $remote_url."\n";

   $socket = new IO::Socket::INET (PeerAddr => $remote_host,
                               PeerPort => $remote_port,
                               Proto    => "tcp",
                               Type     => SOCK_STREAM)
   or die "Can't connect to $remote_host:$remote_port : $!\n";

   print $socket "GET $remote_url HTTP/1.0\n";
   print $socket "Accept: */*\n";
   print $socket "User-Agent: Tk-DynIP ($version)\n";
   print $socket "Connection: Keep-Alive\n";
   print $socket "Authorization: Basic $encoded\n";
   print $socket "\r\n\r\n";
   @socket_buffer = <$socket>;
  
   # Debug
   foreach(@socket_buffer){
      #Debug
      #print $_;
      if ($_ =~ /badauth/){
         $dynstate = "Invalid username/password.";
         #Debug
         #print $dynstate."\n";
      }
      elsif ($_ =~ /nochg/){
         $dynstate = "No change necessary.";
         #Debug
         #print $dynstate."\n";
      }
      elsif($_ =~ /good/){
         $dynstate = "Updated sucessfully.";
         #Debug
         #print $dynstate."\n";
      }
      elsif($_ =~ /nohost/){
         $dynstate = "Host type doesn't match/exist.";
         #Debug
         #print $dynstate."\n";
      }
      elsif($_ =~ /abuse/){
         $dynstate = "Abuse host is blocked.";
         #Debug
         #print $dynstate."\n";
      }
      else{
        #Debug
        print $_
      }
   }
}
