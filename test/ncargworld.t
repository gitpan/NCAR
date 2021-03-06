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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# This program creates a colorful picture to serve as a test for the
# translator.  It is based on EZMAP example 10 and parts of the new
# PLOTCHAR test program.
#
# Assume you have a FORTRAN function that, given the position of a
# point on the surface of the earth, returns the real value of some
# physical quantity there.  You would like to split the full range of
# values of the quantity into intervals, associate a different color
# with each interval, and then draw a colored map of the resulting
# globe.  One way to do this is to use the contouring package CONPACK;
# another way to do it is given below.
#
# This program constructs a rectangular cell array covering the part
# of the plotter frame occupied by a selected map of the globe.  Each
# element of the cell array occupies a small rectangular portion of
# the plotter frame.  The EZMAP routine MAPTRI, which does the inverse
# transformations, is used to find the values of latitude and longitude
# associated with each cell; these can be used to obtain the value of
# the physical quantity and therefore the color index associated with
# the cell.  When the cell array is complete, it is drawn by a call to
# the GKS routine GCA.
#
# Define an integer array in which to build the cell array.
#
my $ICRA = zeroes long, 1000, 1000;
#
# NCLS specifies the number of cells along each edge of the cell array.
# Use a positive value less than or equal to 1000.
#
my $NCLS = 300;
#
# NCLR specifies the number of different colors to be used.
#
my $NCLR = 64;
#
# PROJ is the desired projection type.  Use one of 'LC', 'ST', 'OR',
# 'LE', 'GN', 'AE', 'SV', 'CE', 'ME', or 'MO'.
#
my $PROJ = 'OR';
#
# PLAT and PLON are the desired latitude and longitude of the center of
# the projection, in degrees.
#
my ( $PLAT, $PLON ) = ( 20. , -105. );
#
# ROTA is the desired final rotation of the map, in degrees.
#
my $ROTA = 15.;
#
# SALT, ALFA, and BETA are the desired values of the parameters 'SA',
# 'S1', and 'S2', which are only used with a satellite-view projection.
# SALT is the distance of the satellite from the center of the earth,
# in units of earth radii.  ALFA is the angle, in degrees, between the
# line of sight and the line to the center of the earth.  BETA is used
# only when ALFA is non-zero; it is the angle, in degrees, measured
# counterclockwise, from the plane passing through the satellite, the
# center of the earth, and the point which is due east on the horizon
# to the plane in which the line of sight and the line to the center
# of the earth both lie.
#
my ( $SALT,$ALFA,$BETA ) = ( 1.25 , 15. , 90. );
#
# JLTS, PLM1, PLM2, PLM3, and PLM4 are the required arguments of the
# EZMAP routine MAPSET, which determines the boundaries of the map.
#
my $JLTS = 'MA';
my $PLM1 = float [ 0. , 0. ];
my $PLM2 = float [ 0. , 0. ];
my $PLM3 = float [ 0. , 0. ];
my $PLM4 = float [ 0. , 0. ];
#
# IGRD is the spacing, in degrees, of the EZMAP grid of latitudes and
# longitudes.  IGRD = 0 turns the grid off.
#
my $IGRD = 0;
#
# Define the constant used to convert from degrees to radians.
#
my $DTOR = .017453292519943;
#
# Define the color indices required.  0 and 1 are used for black and
# white (as is customary); the next NCLR values are distributed between
# pure blue (color 2) and pure red (color NCLR+1).  The colors NCLR+2,
# NCLR+3, and NCLR+4 are used for character shadows, outlines, and
# principal bodies, respectively.
#
&NCAR::gscr (1,0,0.,0.,0.);
&NCAR::gscr (1,1,1.,1.,1.);
#
for my $ICLR ( 1 .. $NCLR ) {
  &NCAR::gscr (1,1+$ICLR,($ICLR-1)/($NCLR-1),0.,($NCLR-$ICLR)/($NCLR-1));
}
#
&NCAR::gscr (1,$NCLR+2,0.,0.,0.);
&NCAR::gscr (1,$NCLR+3,1.,1.,0.);
&NCAR::gscr (1,$NCLR+4,0.,1.,1.);
#
# Set the EZMAP projection parameters.
#
&NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
if( $PROJ eq 'SV' ) {
  &NCAR::mapstr ('SA',$SALT);
  &NCAR::mapstr ('S1',$ALFA);
  &NCAR::mapstr ('S2',$BETA);
}
#
# Set the limits of the map.
#
&NCAR::mapset ($JLTS,$PLM1,$PLM2,$PLM3,$PLM4);
#
# Set the grid spacing.
#
&NCAR::mapsti ('GR - GRID SPACING',$IGRD);
#
# Turn off the drawing of labels.
#
&NCAR::mapsti ('LA - LABELLING',0);
#
# Turn off the drawing of the perimeter.
#
&NCAR::mapsti ('PE - PERIMETER',0);
#
# Initialize EZMAP, so that calls to MAPTRI will work properly.
#
&NCAR::mapint;
#
# Fill the cell array.  The data generator is rigged to create
# values between 0 and 1, so as to make it easy to interpolate to
# get a color index to be used.  Obviously, the statement setting
# DVAL can be replaced by one that yields a value of some real data
# field of interest (normalized to the range from 0 to 1).
#
for my $I ( 1 .. $NCLS ) {
  my $X=&NCAR::cfux(.05+.90*(($I-1)+.5)/($NCLS));
  for my $J ( 1 .. $NCLS ) {
    my $Y=&NCAR::cfuy(.05+.90*(($J-1)+.5)/($NCLS));
    &NCAR::maptri ($X,$Y, my ( $RLAT,$RLON ) );
    if( $RLAT != 1E12 ) {
	my $DVAL=.25*(1.+cos($DTOR*15.*$RLAT))+
                 .25*(1.+sin($DTOR*15.*$RLON))*cos($DTOR*$RLAT);
        set( $ICRA, $I-1, $J-1, 
             &NCAR::Test::max( 2,&NCAR::Test::min($NCLR+1,2+int($DVAL*($NCLR)))) );
    } else {
        set( $ICRA, $I-1, $J-1, 0 );
    }
  }
}
#
# Draw the cell array.
#
&NCAR::gca (&NCAR::cfux(.05),&NCAR::cfuy(.05),
            &NCAR::cfux(.95),&NCAR::cfuy(.95),
            1000,1000,1,1,$NCLS,$NCLS,$ICRA);
#
# Quadruple the line width and put a map on top of the cell array.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (4.);
&NCAR::mapdrw;
#
# Using a doubled line width, put a bunch of logos on the globe.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
&NCAR::pcseti ('MA - MAPPING FLAG',1);
&NCAR::pcsetr ('OR - OUT-OF-RANGE FLAG',1.E12);
&NCAR::pcseti ('SF - SHADOW FLAG',1);
&NCAR::pcsetr ('SX - SHADOW OFFSET IN X',-.09);
&NCAR::pcsetr ('SY - SHADOW OFFSET IN Y',-.06);
&NCAR::pcseti ('OF - OUTLINE FLAG',1);
&NCAR::pcseti ('SC - SHADOW COLOR   ',$NCLR+2);
&NCAR::pcseti ('OC - OUTLINE COLOR  ',$NCLR+3);
&NCAR::pcseti ('CC - CHARACTER COLOR',$NCLR+4);
&NCAR::plchhq (-225.,-60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-225.,-30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-225.,  0.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-225.,+30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-225.,+60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-105.,-60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-105.,-30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-105.,  0.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-105.,+30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq (-105.,+60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq ( +15.,-60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq ( +15.,-30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq ( +15.,  0.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq ( +15.,+30.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);
&NCAR::plchhq ( +15.,+60.,':F25Y250:NCAR GRAPHICS',8.,0.,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/ncargworld.ncgm';
