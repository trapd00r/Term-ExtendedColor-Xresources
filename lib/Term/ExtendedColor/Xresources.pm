#!/usr/bin/perl
package Term::ExtendedColor::Xresources;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.042';
  @ISA     = qw(Exporter);
  @EXPORT_OK = qw(
    set_xterm_color
    get_xterm_color
    get_xterm_colors
  );
}
use Carp qw(croak);
use Term::ReadKey;

# Convience function for get_xterm_colors
sub get_xterm_color {
  get_xterm_colors(@_);
}

sub get_xterm_colors {
  my $arg = shift;

  my $index = $arg->{index} || [0 .. 255];


  my @indexes;

  if(ref($index) eq 'ARRAY') {
    push(@indexes, @{$index});
  }
  elsif(ref($index) eq '') {
    push(@indexes, $index);
  }

  if( grep { $_ < 0 } @indexes ) {
    croak("Index must be a value within 0 .. 255, inclusive\n");
  }

  open(my $tty, '<', '/dev/tty') or croak("Can not open /dev/tty: $!\n");

  my $colors;
  for my $i(@indexes) {
    next if not defined $i;

    ReadMode('raw', $tty);

    print "\e]4;$i;?\a"; # the '?' indicates a query

    my $response = '';
    $response .= ReadKey(0, $tty) for(0 .. 22);


    ReadMode('normal');

    my($r, $g, $b) = $response =~ m{
      rgb: ([A-Za-z0-9]{2}).*/
           ([A-Za-z0-9]{2}).*/
           ([A-Za-z0-9]{2})
       }x;

    $colors->{$i}->{raw} = $response;
    # Return in base 10 by default
    if($arg->{type} eq 'hex') {
      $colors->{$i}->{red}   = $r; # ff
      $colors->{$i}->{green} = $g;
      $colors->{$i}->{blue}  = $b;
      $colors->{$i}->{rgb}   = "$r$g$b";
    }
    else {
      ($r, $g, $b) = (hex($r), hex($g), hex($b));

      $colors->{$i}->{red}   = $r; # 255
      $colors->{$i}->{green} = $g;
      $colors->{$i}->{blue}  = $b;
      $colors->{$i}->{rgb}   = "$r/$g/$b"; # 255/255/0
    }
  }
  return $colors;
}

sub set_xterm_color {
  my $old_colors = shift;

  if(ref($old_colors) ne 'HASH') {
    croak("Hash reference expected");
  }

  my %new_colors;

  for my $index(keys(%{$old_colors})) {

    if( ($index < 0) or ($index > 255) ) {
      next;
    }
    if($old_colors->{$index} !~ /^[A-Fa-f0-9]{6}$/) { # Allow stuff like fff ?
      next;
    }

    my($r, $g, $b) = $old_colors->{$index} =~ m/(..)(..)(..)/;
    $new_colors{$index} = "\e]4;$index;rgb:$r/$g/$b\e\\";
  }

  return \%new_colors;
}


1;

__END__

=pod

=head1 NAME

Term::ExtendedColor::Xresources - Query and set various Xresources

=head1 SYNOPSIS

    use Term::ExtendedColor::Xresources qw(get_xterm_color set_xterm_color);

    # Get RGB values for all defined colors
    my $colors = get_xterm_color({
      index => [0 .. 255], # default
      type  => 'hex',      # default is base 10
    });


=head1 DESCRIPTION

B<Term::ExtendedColor::Xresources> provides functions for changing and querying
the underlying X terminal emulator for various X resources.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 set_xterm_color()

  # Switch yellow and red
  my $new_colors = set_xterm_color({
    220 => 'ff0000',
    196 => 'ffff00',
  });

  print $_ for values %{$new_colors};

Expects a hash reference where the keys are color indexes (0 .. 255) and the
values hexadecimal representations of the color values.

Returns a hash with the indexes as keys and the appropriate escape sequences as
values.

=head2 get_xterm_color()

  my $defined_colors = get_xterm_color({ index => [0 .. 255] });

  print $defined_colors->{4}->{red}, "\n";
  print $defined_colors->{8}->{rgb}, "\n";

B<0 - 15> is the standard I<ANSI> colors, all above are extended colors.

Returns a hash reference with the the index colors as keys.
By default the color values are in decimal.

The color values can be accessed by using their name:

  my $red = $colors->{10}->{red};

Or by using the short notation:

  my $red = $colors->{10}->{r};

The full color string can be retrieved like so:

  my $rgb = $colors->{10}->{rgb};

The C<raw> element is the full response from the terminal, including escape
sequences.

=head2 get_xterm_colors()

The same thing as B<get_xterm_color()>. Will be deprecated.

=head1 SEE ALSO

L<Term::ExtendedColor>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the Term::ExtendedColor::Xresources L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
