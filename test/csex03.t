# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;

#
#       $Id: csex03.f,v 1.2 1999/01/28 23:55:28 fred Exp $
#
#
#  Demo of extrapolation into data sparse regions using CSA1XS.
#
#  The number of input data points.
#
my $NDATA = 9;
#
#  The number of output data points.
#
my $NX = 101;
#
#  The maximum number of knots used in any call.
#
my $NCF = 8;
#
#  The size of the workspace.
#
my $NWRK = $NCF*($NCF+3);
#
#  Dimension the arrays.
#
my $XDATA = zeroes float, 1, $NDATA;
my $XDATAT = zeroes float, $NDATA;
my $WORK = zeroes float, $NWRK;
my $XO = zeroes float, $NX;
my $Y1 = zeroes float, $NX;
my $Y2 = zeroes float, $NX;
#
#  Specify the input data.
#
my @xdata = ( 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.90, 1.0 );
for my $I ( 1 .. $NDATA ) {
  set( $XDATA, 0, $I-1, $xdata[$I-1] );
}
my $YDATA = float [ 0.0, 0.2, 0.4, -0.4, -1.0, 0.2, 0.5, 0.4, 0.0 ];
#
#  Define the output coordinates.
#
my $XINC = 1./($NX-1);
for my $I ( 1 .. $NX ) {
  set( $XO, $I-1, ($I-1)*$XINC );
}
#
#  Calculate the approximating curve with no extrapolation.  Note
#  the unexpected oscillation in the approximation curve.
#
my $SSMTH = 0.;
my $NDERIV = 0;
my $WTS = float [ ( -1 ) x $NDATA ];
&NCAR::csa1xs ($NDATA,$XDATA,$YDATA,$WTS,$NCF,$SSMTH,$NDERIV,$NX,$XO,$Y1,$NWRK,$WORK,my $IER);
if( $IER != 0 ) {
  printf( STDERR "Error %3d returned from CSA1XS\n", $IER );
  exit( 0 );
}
#
#  Calculate the approximating curve with the extrapolation parameter
#  set to 1.0.
#
$SSMTH = 1.0;
&NCAR::csa1xs ($NDATA,$XDATA,$YDATA,$WTS,$NCF,$SSMTH,$NDERIV,$NX,$XO,$Y2,$NWRK,$WORK,$IER)       ;
if( $IER != 0 ) {
  printf( STDERR "Error %3d returned from CSA1XS\n", $IER );
  exit( 0 );
}
#
#  Draw a plot of the approximation curves and mark the original points.
#
for my $I ( 1 .. $NDATA ) {
  set( $XDATAT, $I-1, at( $XDATA, 0, $I-1 ) );
}
&DRWFT1($NDATA,$XDATAT,$YDATA,$NX,$XO,$Y1,$Y2);
#
sub DRWFT1 {
  my ($NUMIN,$X,$Y,$NUMOUT,$XO,$Y1,$Y2) = @_;
#
#  This subroutine uses NCAR Graphics to plot curves.
#
#  Define error file, Fortran unit number, workstation type,
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Vertical position for initial curve.
#
  my $YPOS_TOP = 0.86;
#
#  Open GKS, open and activate a workstation.
#
  &NCAR::gopks ($IERRF, my $ISZDM);
  &NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
  &NCAR::gacwk ($IWKID);
#
#  Define a color table.
#
  &NCAR::gscr($IWKID, 0, 1.0, 1.0, 1.0);
  &NCAR::gscr($IWKID, 1, 0.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 2, 1.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 3, 0.0, 1.0, 0.0);
  &NCAR::gscr($IWKID, 4, 0.0, 0.0, 1.0);
  &NCAR::gsclip(0);
#
#  Plot the main title.
#
  &NCAR::plchhq(0.50,0.95,':F25:Data sparse areas',0.030,0.,0.);
#
#  Graph the approximation curve with extrapolation into data sparse
#  regions turned off.  Note the unexpected oscillation in the curve.
#
#
#  Draw a background grid for the first curve.
#
  my $YB = -2.0;
  my $YT =  1.0;
  &BKGFT1($YPOS_TOP,'SMTH = 0.',$YB,$YT);
  &NCAR::gridal(5,5,5,1,1,1,10,0.0,$YB);
#
#  Graph the approximation curve with no extrapolation into data
#  sparse areas.
#
  &NCAR::gpl($NUMOUT,$XO,$Y1);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.);
  &NCAR::gspmci(4);
  &NCAR::gpm($NUMIN,$X,$Y);
#
#  Graph the approximation curve with extrapolation parameter set to 1.
#
  &BKGFT1($YPOS_TOP-0.45,'SMTH = 1.',$YB,$YT);
  &NCAR::gridal(5,5,5,1,1,1,10,0.0,$YB);
  &NCAR::gpl($NUMOUT,$XO,$Y2);
  &NCAR::gpm($NUMIN,$X,$Y);
  &NCAR::frame();
#
  &NCAR::gdawk($IWKID);
  &NCAR::gclwk($IWKID);
  &NCAR::gclks();
#
}

sub BKGFT1 {
  my ($YPOS,$LABEL,$YB,$YT) = @_;
#
#  This subroutine draws a background grid.
#
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
#  Plot the curve label using font 21 (Helvetica).
#
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq(0.20,$YPOS - 0.2,$LABEL,0.023,0.,-1.);
  &NCAR::set(0.13,0.93,$YPOS-0.28,$YPOS,0.0,1., $YB, $YT, 1);
#
#  Draw a horizontal line at Y=0. using color index 2.
#
  my $XX = float [ 0, 1 ];
  my $YY = float [ 0, 0 ];
  &NCAR::gsplci(2);
  &NCAR::gpl(2,$XX,$YY);
  &NCAR::gsplci(1);
#
#  Set Gridal parameters.
#
#
#   Set LTY to indicate that the Plotchar routine PLCHHQ should be used.
#
  &NCAR::gaseti('LTY',1);
#
#   Size and format for X axis labels.
#
  &NCAR::gasetr('XLS',0.02);
  &NCAR::gasetc('XLF','(F3.1)');
#
#   Size and format for Y axis labels.
#
  &NCAR::gasetr('YLS',0.02);
  &NCAR::gasetc('YLF','(F5.1)');
#
#   Length of major tick marks for the X and Y axes.
#
  &NCAR::gasetr('XMJ',0.02);
  &NCAR::gasetr('YMJ',0.02);
#
}

rename 'gmeta', 'ncgm/csex03.ncgm';
