#!/usr/bin/perl
package Term::ExtendedColor::Xresources;

our $VERSION  = '0.001';

require Exporter;
@ISA = 'Exporter';
our @EXPORT = qw(set_xterm_color get_xterm_colors);

use strict;
use Carp 'croak';
use Term::ReadKey;

sub get_xterm_colors {
  my $index = shift;

  if( (not defined($index)) and (ref($index) eq '') ) {
    $index = [0 .. 255];
  }

  my @indexes;

  if(ref($index) eq 'ARRAY') {
    push(@indexes, @{$index});
  }
  elsif(ref($index) eq '') {
    push(@indexes, $index);
  }
  else {
    croak("Reference type " . ref($index) . " not supported\n");
  }

  if( grep { $_ < 0 } @indexes ) {
    croak("Index must be a value within 0 .. 255, inclusive\n");
  }

  open(my $tty, '<', '/dev/tty') or croak("Can not open /dev/tty: $!");

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

    $colors->{$i}->{red}   = $r;
    $colors->{$i}->{green} = $g;
    $colors->{$i}->{blue}  = $b;
    $colors->{$i}->{rgb}   = "$r$g$b";

  }
  return $colors;
}

sub set_xterm_color {
  my $index = shift; # color no 8
  my $color = shift; # ff0000

  if(!defined($index) or ($index eq '')) {
    confess("Need index color (0..255)");
  }
  if(!defined($color) or ($color eq '')) {
  confess("Need color specification in valid hex");
  }

  if(($index < 0) or ($index > 255)) {
    confess("Invalid index: $index. Valid numbers are 0-255\n");
  }
  if($color !~ /^([A-Fa-f0-9]{6}$)/) {
    confess("Invalid hex: $color\n");
  }

  my($r_hex, $g_hex, $b_hex) = $color =~ /(..)(..)(..)/g;
  return("\e]4;$index;rgb:$r_hex/$g_hex/$b_hex\e\\");
}


=pod

=head1 NAME

Term::ExtendedColor::Xresources - Query and set various Xresources

=head1 SYNOPSIS

    use Term::ExtendedColor::Xresources;

    # Get RGB values for all defined colors
    my $colors = get_xterm_colors( [0 .. 255] );

=head1 DESCRIPTION

Term::ExtendedColor::Xresources provides functions for changing and querying the
underlying terminal for various X resources.

=head1 EXPORTS

=head2 set_xterm_color()

Parameters: $index, $color

Returns:    $string

  # Change color index 220 from ffff00 to ff0000
  my $color = set_xterm_color(220, 'ff0000');
  print $color;

=head2 get_xterm_colors()

Parameters: $index | \@indexes

Returns:    \%colors

  my $defined_colors = get_xterm_colors( [ 0 .. 16 ] );
  print $defined_colors->{4}->{red}, "\n";
  print $defined_colors->{8}->{rgb}, "\n";

Returns a hash reference containing RGB values of the defined colors.
If omitting any parameters, defaults to all colors, 0 .. 255.

  10 => {
    red   => "b0",
    green => "3b",
    blue  => "31",
    rgb   => "b03b31",
  },

  11 => {
    red   => "bd",
    green => "f1",
    blue  => "3d",
    rgb   => "bdf13d",
  },


=head1 SEE ALSO

Term::ExtendedColor

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

Written by Magnus Woldrich

=head1 COPYRIGHT

Copyright 2010 Magnus Woldrich <magnus@trapd00r.se>. This program is free
software; you may redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;
