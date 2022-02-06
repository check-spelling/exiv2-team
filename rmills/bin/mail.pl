#!/usr/bin/perl -- -*-perl-*-
#
# ------------------------------------------------------------
# script:  mail.pl
# Authors: David Wood (dwood@plugged.net.au)
#          Brad Marshall (bmarshal@plugged.net.au)
# Date:    7 June 1997
#
# Purpose: Creates and sends an SMTP/MIME e-mail message.
#
# Usage: Called from cron or a shell to send a message.
#
# Location of the script:  Immaterial to operation.
#
# Copyright (c) 1997-9 Plugged In Software Pty Ltd.
# Released under the GNU GPL - see http://www.gnu.org/copyleft/gpl.html
#
# Modification History:
#	11 Dec 1998:  Initial revision, based on dwood's wrc.pl
#	17 Apr 1998:  Changed to act more like /bin/mail for ORA
#
# ------------------------------------------------------------

# ---------------------------------------------------------
# |            MAIN PROGRAM                               |
# ---------------------------------------------------------
# Packages
use strict;
use Socket;        # Required for network communications

# ---------------------------------------------------------
# |            CONSTANTS AND GLOBAL VARIABLES             |
# ---------------------------------------------------------

# Set some default values:
my($CRLF) = "\r\n";
my($MIMEversion) = "1.0";
my($DEFAULT_CONTENT_TYPE) = "application/octet-stream";
my($content_type) = "";
my($padchar) = "=";
my($LINESIZE) = 76;

# Set some flags for use in determining state:
my($_attachment_encoded) = 0;
my($boundary) = "";
my($message) = "";
my($_filename) = "";
my($last_processed) = -1;
my($no_stdin) = 0;
my($headeroverride) = 0;

# Declare some variables for use in the SMTP session:
my ( $mailcmd, $in_addr, $proto, $addr );
my ( $mailtest, $error_test );

# Base 64 encode characters table:
my(@encode_table) = (
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
);

# Define global variables used for configuration information:
my($mailhost) = "mailhost.plugged.net.au";
my($mailport) = 25;
my($to) = "";
my($recipient);
my(@recipients);
my($from) = "no_address\@nowhere.com";
my($cc) = "";
my($bcc) = "";
my($replyto) = "";
my($subject) = "No Subject";
my($body) = "";
my($attachment_list) = "";

# Declare an array to hold files for attachment:
my(@file);

# Since we're being strict, we need to pre-declare all vars:
my($i, $j, @attachments, $filename, $file_buffer, @attachments_encoded, $attachment, $flag, $extension, $random_int, $the_header, $tmp_incoming_data, $header, @decoded_attachment_data, $plain_text, $element, $encoded_attachment, @buffer,
 $encode_count, $buffer_string, $tmp_string); 

# ---------------------------------------------------------
# |            REAL WORK STARTS                           |
# ---------------------------------------------------------
# If this script was called without any command line information,
# there is not enough information to proceed.  Instead, return
# a usage message.
unless ($#ARGV >= 0) {
	&usage;
}

# Parse the command line to gather all necessary information.
&parseCmdLine;

unless ($no_stdin) {
    while (<STDIN>) {
	if ($_ =~ /^\./) {
		last;
	}
	$body .= $_;
    }
    print STDOUT "EOT\n";
}

# DBG
# Dump the major vars to the screen for review and exit.
print "To:       $to\n";
print "From:     $from\n";
print "CC:       $cc\n";
print "BCC:      $bcc\n";
print "Reply-To: $replyto\n";
print "Subject:  $subject\n";
print "Body:     $body\n";
print "Mailhost: $mailhost\n";
print "Port:     $mailport\n";
print "Attachments: $attachment_list\n";
print "Last arg processed: $last_processed\n";
#exit;

# ---------------------------------------------------------
# |            CREATE MIME ATTACHMENTS                    |
# ---------------------------------------------------------

# Create MIME attachments for each file named as an attachment
if ($#attachments >= 0) {
	for $j (0...$#attachments) {
	    $filename = $attachments[$j];
	    open (INCOMING, $filename) || die "Can't open $filename\n";
	    $file_buffer = "";
	    while (<INCOMING>) {
	    	$file_buffer .= $_;
	    }
	    close(INCOMING);
	
            # BWM 17/03/98
            # Fix to correct filename so it doesn't include path name
            @file = split(/\//, $filename);
            $_filename = @file[$#file];
	    $attachments_encoded[$j] = &printEncoded("$file_buffer");
	    $j++;
	
	}
}

# ---------------------------------------------------------
# |            CREATE THE MESSAGE                         |
# ---------------------------------------------------------
$boundary = &createBoundaryMarker;

$message = "From: " . $from . $CRLF;
$message .= "To: $to" . $CRLF;
$message .= "Cc: $cc" . $CRLF;
$message .= "Bcc: $bcc" . $CRLF;
if ($replyto) {
	$message .= "Reply-To: $replyto" . $CRLF;
}
$message .= "Subject: $subject" . $CRLF;

if ($attachment_list) {
	$message .= "MIME-Version: $MIMEversion" . $CRLF;
	$message .= "Content-Type: multipart/mixed; boundary=\"$boundary\"" . $CRLF . $CRLF;
	$message .= "This is a multi-part message in MIME format." . $CRLF . $CRLF;
        if ($body) {
             $message .= "--$boundary" . $CRLF;
             $message .= "Content-Type: text/plain; charset=us-ascii" 
                         . $CRLF;
             $message .= "Content-Transfer-Encoding: 7bit" . $CRLF;
        }
}

unless ($headeroverride) {
	$message .= $CRLF;
}

if ($body) {
        $message .= $body . $CRLF; # Add the rest of the message
        $message .= $CRLF;
}

if ($attachment_list) {
	$message .= $CRLF . "--" . $boundary;
	
	foreach $attachment (@attachments_encoded) {
	    $message .= $CRLF . $attachment . $CRLF;
	    $message .= "--$boundary";
	}
	
	$message .= "--" . $CRLF;
}

# ---------------------------------------------------------
# |            SEND THE MESSAGE                           |
# ---------------------------------------------------------

$in_addr = (gethostbyname($mailhost))[4];
$addr = sockaddr_in($mailport, $in_addr);

$proto = getprotobyname('tcp');

# Create a socket
socket(S, AF_INET, SOCK_STREAM, $proto) or die "socket: $!";

# Connect the socket to the host
connect(S, $addr) or die "Connect: $!";

# fflush socket after every write
select (S); $| = 1; select (STDOUT);

# Send SMTP request to the server
die "ERROR: $!" unless &expect(220,500);
print $mailcmd;

# Be nice, say hello to the mail host.
# Of course, say in MIME-wise with EHLO.
print S "EHLO $mailhost" . $CRLF;
die "ERROR: $!" unless &expect(250,501);
print $mailcmd;

print "Connected to $mailhost." . $CRLF;

print S "MAIL FROM: $from" . $CRLF;
print "From: $from" . $CRLF;
die "ERROR: $!" unless &expect("ok",500);
print $mailcmd;

# Break the recipient list into individual addresses in
# order to create a proper envelope.
@recipients = split /,/, $to;
foreach $recipient (@recipients) {
     print S "RCPT TO: $recipient" . $CRLF;
     print "To: $recipient" . $CRLF;
     die "ERROR: $!" unless &expect("ok",500);
     print $mailcmd;
}

print S "DATA" . $CRLF;
print "Sending message...";
die "ERROR: $!" unless &expect(354,50);
print $mailcmd;

print S "$message" . $CRLF;
#print "$message" . $CRLF;
print S "." . $CRLF;
#print "." . $CRLF;
die "ERROR: $!" unless &expect(250,500);
#print $mailcmd;

print S "QUIT" . $CRLF;
#print "QUIT" . $CRLF;
die "ERROR: $!" unless &expect(221,50);
#print $mailcmd;

# DBG
print "Finished\n\n";

# Clean up and exit
close(S);
exit;

# ---------------------------------------------------------------
# |  Everything below here is a subroutine.                     |
# ---------------------------------------------------------------
sub usage {

    print <<ENDOFUSAGE;
        mail.pl [-u] [-h] [-f from] [-m mailhost] [-p port]
		[-s subject] [-c cc-addr] [-b bcc-addr] [-r replyto-addr]
		[-a attachment#1[:attachment#2...]] [-w] to_addresses
	-a		List of files to attach, colon seperated
	-b		List of blind carbon copy addresses
	-c		List of carbon copy addresses
	-f		Email sender's address (FROM:)
	-h		Shows the man page (help)
	-m		SMTP mailhost (name or IP address)
	-w		Do not wait on STDIN for message part
        -o              Override headers
	-p		Port to use when connecting to mailhost
	-r		Email reply-to address
	-s		Subject to use
	-u		Shows this usage information
	to_addresses    Email recipients address (TO:) in a comma
                  seperated list

ENDOFUSAGE

  exit(0);

} # End sub usage

sub manpage {

    my($pager) = 'more';
    $pager = $ENV{'PAGER'} if $ENV{'PAGER'};
    if ( $ENV{'TERM'} =~ /^(dumb|emacs)$/ ) {
    system ("pod2text $0");
    } else {
    system ("pod2man $0 | nroff -man | $pager");
    }
    exit (0);
}

sub parseCmdLine {

     foreach $i (0...$#ARGV) {

    if ( $ARGV[$i] =~ /^\-(\w)$/ ) {

        $flag = $1;
        $_ = $flag;

      SWITCH: {

          /u/     and &usage, last SWITCH;
          /h/     and &manpage, last SWITCH;
          /f/     and $from = $ARGV[$i+1], $last_processed += 2, last SWITCH;
          /r/     and $replyto = $ARGV[$i+1], $last_processed += 2, last SWITCH;
          /m/     and $mailhost = $ARGV[$i+1], $last_processed += 2, last SWITCH;
          /o/     and $headeroverride = 1, last SWITCH;
          /w/     and $no_stdin = 1, $last_processed++, last SWITCH;
          /p/     and $mailport = $ARGV[$i+1], $last_processed += 2, last SWITCH;
	  /a/     and $attachment_list = $ARGV[$i+1], $last_processed += 2, last SWITCH;
	  /s/	  and $subject = $ARGV[$i+1], $last_processed += 2, last SWITCH;
	  /c/     and $cc = $ARGV[$i+1], $last_processed += 2, last SWITCH;
	  /b/	  and $bcc = $ARGV[$i+1], $last_processed += 2, last SWITCH;

      } # end SWITCH
    } # end if/else
    } # end foreach

    # If attachments were found, put them into the attachments array
    if ($attachment_list) {
    	@attachments = split(/:/, $attachment_list);
    }

    # Any arguments left on the command line after the last 
    # switch processed should be To: addresses.
    foreach $i (($last_processed + 1)...$#ARGV) {
	if ($to) {
		$to .= ",";
	}
	# Provide some basic error checking.  Don't append anything
	# to the To: list unless it has an '@' sign in it.
	if ($ARGV[$i] =~ /\@/) {
		$to .= $ARGV[$i];
	}
    }

} # end sub parseCmdLine

sub setContentType {

      # Need to determine the type from filename

      # set a default content type in case nothing can be found
      $content_type = $DEFAULT_CONTENT_TYPE;

      # get the start of the filename extension
      if ( $_filename =~ /.*\.(\w{3,4})$/ ) {

    	# extract the extension
    	$extension = $1;

        # DBG
        print "file extension: $extension\n";

        # try some common extensions

        if ($extension eq "gif") {

          # GIF
          $content_type = "image/gif";

        } elsif ($extension eq "jpg" || $extension eq "jpeg") {

          # JPEG
          $content_type = "image/jpeg";

        } elsif ($extension eq "txt") {

          # text
          $content_type = "text/plain";

        } elsif ($extension eq "htm" || $extension eq "html") {

          # HTML
          $content_type = "text/html";

        } elsif ($extension eq "mpg" || $extension eq "mpeg") {

          # MPEG
          $content_type = "video/mpeg";

        } # end if extension...

      } # end if start_extension...

} # end sub setContentType


sub createBoundaryMarker {

    # random number as integer
    $random_int = int(rand(1000)) * 98765;

    # create the marker
    $boundary="====PLUGGEDIN====" . $random_int . "====_";

    return $boundary;

} # end subcreateBoundaryMarker


sub createHeader {

    # the header to be created
    $the_header = "";

    # set a content type
    &setContentType;

    # is the content type text?
    if ($content_type =~ /^text/ ) {

      # yes, it's text

      # create header
      $the_header = "Content-Type: $content_type; charset=us-ascii; name=\"$_filename\"\n" .
               "Content-Transfer-Encoding: 7bit\n" .
               "Content-Disposition: inline; filename=\"$_filename\"\n\n";

    } else {

      # not text, therefore the content will be base64 encoded

      # create header
      $the_header="Content-Type: $content_type; name=\"$_filename\"\n" .
               "Content-Transfer-Encoding: base64\n" .
               "Content-Disposition: inline; filename=\"$_filename\"\n\n";

    }

    return $the_header;
}

sub printEncoded {

    # DHW:  Added the requirement for the incoming data to be passed as
    #       a parameter.  It is a String.
    $tmp_incoming_data = pop(@_);

    # DBG
    #print "The input to \&printEncoded was $tmp_incoming_data\n";

    # Turn the string input into an array of characters from processing.
    @decoded_attachment_data = split(//,$tmp_incoming_data);

    # DBG
    #print "The decoded_attachment_data array consists of:\n";
    #foreach $element (@decoded_attachment_data) {
        #print "$element\n";
    #}

    # encoded attachment size counter
    $encode_count = 0;

    # is there anything to encode?
    if (@decoded_attachment_data == 0) {

      # nothing to encode

      # DBG
      print "Nothing to encode!\n\n";

      return "null";

    }

    # Set the MIME content type for this attachment
    &setContentType;

    # DBG
    print "Content type is: $content_type\n";

    # create the MIME header
    $header = &createHeader;

    # initialise the encode string
    $encoded_attachment = $header;

    # DBG
    #print "After setting the header, \$encoded_attachment is: $encoded_attachment\n";

    # Is the content type text of some form?
    if ($content_type =~ /^text/i) {

      # the encoded attachment is plain text - no need to encode

      # DBG
      print "The content type is text: no encoding needed!\n";

      $plain_text = "";
      foreach $element (@decoded_attachment_data) {
    	$plain_text .= $element;
      }

      # DBG
      print "plain_text length = " . length($plain_text) . "\n";
      #print "plain_text is: $plain_text\n";

      $encoded_attachment .= $plain_text;

    } else {

      # DBG
      print "The content type is NOT text: encoding!\n";

      # create a suitable buffer - each 3 decoded bytes, becomes 4 encoded
      @buffer = ('');

      # DBG
      print "printEncoded: d_a_d length: " . @decoded_attachment_data . "\n";

      # go through the attachment
      for ($i=0; $i < ( @decoded_attachment_data - 2 ); $i+=3) {

        # convert 3 bytes to 4 encoded characters
        $buffer[$encode_count++] = $encode_table[((vec($decoded_attachment_data[$i],0,8) & 0xFC) >> 2) ];
        $buffer[$encode_count++] = $encode_table[(((vec($decoded_attachment_data[$i],0,8) & 0x03) << 4) | ((vec($decoded_attachment_data[$i+1],0,8) & 0xF0) >> 4)) ];
        $buffer[$encode_count++] = $encode_table[(((vec($decoded_attachment_data[$i+1],0,8) & 0x0F) << 2) | ((vec($decoded_attachment_data[$i+2],0,8) & 0xC0) >>
 6)) ];
        $buffer[$encode_count++] = $encode_table[(vec($decoded_attachment_data[$i+2],0,8) & 0x3F) ];

      }

      # check to see if padding required
      if ( $i < @decoded_attachment_data ) {

        $i -= 3;

        # DBG
        #print "\$i = $i\n";
        print "Padding is required.  At least one byte is left over.\n";

        # there's at least one byte left over
        $buffer[$encode_count++] = $encode_table[((vec($decoded_attachment_data[$i],0,8) & 0xFC) >> 2)];
        $buffer[$encode_count] = $encode_table[((vec($decoded_attachment_data[$i],0,8) & 0x03) << 4)];

        # move to the next char, if any
        $i++;

        # any more bytes left over?
        if ($i < @decoded_attachment_data ) {

          # yes, include it

          # DBG
          print "There is a second byte left over.\n";

          # need to redo the current character
          $buffer[$encode_count++] = $encode_table[(((vec($decoded_attachment_data[$i-1],0,8) & 0x03) << 4) | ((vec($decoded_attachment_data[$i],0,8) & 0xF0) >>
 4))];

          $buffer[$encode_count++] = $encode_table[((vec($decoded_attachment_data[$i],0,8) & 0x0F) << 2)];

        } else {

          # need a pad character
          $buffer[$encode_count++] = $padchar;

      # DBG
      print "Added a pad character\n";

        }

        # need at least one pad character
        $buffer[$encode_count++] = $padchar;

    # DBG
    print "Added a pad character\n";

      }

      # convert to string - put a new line every LINESIZE chars
      $buffer_string = "";
      foreach $element (@buffer) {
    	$buffer_string .= $element;
      }
      for ($i=0; $i<= ($encode_count-$LINESIZE) ; $i+=$LINESIZE) {

        # DBG
        print "Entered the line-wrapping for loop. i=$i\n";

        # convert LINESIZE bytes to string
        $tmp_string = substr($buffer_string,$i,$LINESIZE);
        # add this string to the encoded string, plus a newline
        $encoded_attachment .= $tmp_string . "\n";

        # DBG
        #print "tmp_string: $tmp_string\n";
        #print "encoded_attachment: $encoded_attachment\n\n";

      }

      # do any leftover chars
      if ($i != $encode_count) {

        # convert the remaining bytes to string
        $tmp_string = substr($buffer_string,$i,$encode_count - $i);

        # add this string to the encoded string, plus a newline
        $encoded_attachment .= $tmp_string . "\n";

      }

    }

    # DBG
    print "The buffer holds: $buffer_string\n";

    # set flag to indicate attachment has been encoded
    $_attachment_encoded = 1;

    # DBG
    print "TEMP:  \$encoded_attachment = $encoded_attachment\n\n";

    # attachment is appropriately encoded by now
    return $encoded_attachment;

} # sub printEncoded

sub expect {
  my($ok);
  my($mailtest) = shift;
  my($error_test) = shift;

  # DBG
  #print "test: $mailtest\n";
  #print "error_test: $error_test\n";

  $mailcmd = "";
  while (<S>) {
    $mailcmd .= $_;
    if (/$mailtest/i) {
        $ok = 1;
        last;
    }
    if (/$error_test/i) {
        $ok = 0;
        last;
    }
  }
  return $ok;
}

__END__

=head1 NAME

mail.pl - Send SMTP/MIME email

=head1 SYNOPSIS

B<mail.pl> [B<-a file1[:file2...]>]
        [B<-b bcc list>]
        [B<-c cc list>]
        [B<-f sender>]
        [B<-h>]
        [B<-m mailhost>]
        [B<-o>]
        [B<-w>]
        [B<-p mail port>]
        [B<-r replyto>]
        [B<-s subject>]
        [B<-u>]
        to_addresses
 

=head1 DESCRIPTION

I<mail.pl> allows a user to send SMTP/MIME compliant email 
to a specified list of email addresses.

I<mail.pl> is intended to be a nearly-complete drop-in 
replacement for Unix's /bin/mail, when used to send mail.
This script provides similar command-line arguments but
is extended to enable the sending of MIME-compliant mail
and reduces the need for a local MTA.

Mail is sent via an SMTP-compliant network connection to
a mail transfer agent, possibly on a different machine.

This script will wait on STDIN (as does /bin/mail) for
some text to be used as the first (textual) message body
part.  Unlike /bin/mail, this behavior may be overridden
by use of switch w.  Failure to provide a Subject: on 
the command line does NOT result in the user being asked
for one (this also differs from /bin/mail).

=head1 OPTIONS

=over 6

=item B<-u> (usage)

Display the usage statement.

=item B<-h> (help)

Display the man page.

=item B<-f sender> (Sender's email address)

Provide an email address for the person sending the message.

=item B<-r replyto> (Replyto email address)

Provide a replyto email address for the message.

=item B<-m mailhost> (Mailhost)

Provide the name of the SMTP mailhost used to route SMTP mail.

=item B<-o> (Header Override)

If this flag is set, the message provided must contain additional
headers followed by a blank line and a message body.  It can be
used to write additional headers into a message.  If you use this
option, you must provide the blank line separarting headers and body!

=item B<-w> (No STDIN)

If this flag is given, do not wait on STDIN for the first
(textual) message body part.  The default is that this 
script will wait for input via STDIN for some text to be 
entered.  The text entry is terminated by a Ctrl-D 
interruption or by entering a '.' on a line by itself.  
This flag overrides the default behavior.

=item B<-p mail port> (Mailhost port)

Provide a port number to use when sending mail to the mailhost specified.  The default port is 25, a well-known port used for SMTP mail transfers.

=item B<-s subject> (Subject)

Provide the subject for the mail.

=item B<-a attachment list> (Attachment list)

List of files to be MIME encoded, and attached.  This list is colon-separated if more than one file to attach is given.  For example:

     -a "file1.txt:file2.html:file3.gif:file4.ps"

would attach four files, but

     -a file1.txt

would only attach one file.

=item B<-c cc list> (CC List)

Provides a list of addresses to cc the message to.

=item B<-b bcc list> (BCC List)

Provides a list of addresses to bcc the message to.

=item to_addresses (Recipients' email addresses)

A comma-separated list of email addresses for the recipient of the message.  Each address must include an '@' sign.

=back

=head1 AUTHOR

David Wood <C<dwood@plugged.net.au>> and 
Brad Marshall <C<bmarshal@plugged.net.au>>

=head1 LIMITATIONS

This script is intended to be a drop-in replacement for the UNIX /bin/mail program for sending mail, with enhancements to allow MIME compliance.  However, no attempt has been made to duplicate or replace /bin/mail's e-mail reading and manipulation capabilities.

=head1 SEE ALSO

Plugged In Software

http://www.plugged.net.au/

=cut

