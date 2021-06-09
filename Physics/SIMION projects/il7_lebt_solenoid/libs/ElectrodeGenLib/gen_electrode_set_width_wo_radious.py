# This is a test script to generate a SIMION PA with python
# Date: 2018/03/15
# Author: izpilab, gaudee, ehu
# Description:
#   We will generate the PA file for the repller of our
#   ion source. It is composed by:
#       PE: Plasma electrode. Disk with 4mm width, 90mm diameter
#           and a center hole starting at a diamater of 3.5mm
#           to 17.36mm. This electrode is static.
#       D4, D5, D6: A set of three discs that have a central
#                   hole of 4, 5 and 6mm. They can be conbined
#                   as we want. The width of the disk is 3mm.
#   The minimum distance between electrodes is:
#       a = 5mm, b = 3mm, c = 3mm.


#------------------------------ IMPORTS ----------------------------------#

from libs.SimionLib.PA import *
from libs.FileManipulationLib.files_lib import *
from os import getcwd

#------------------------------ DEFINES ----------------------------------#

#-- define the grid granularity 0.25mm/gu. Since it is cylindrical
#-- we only define dx_mm and dy_mm
dx_mm = 0.25
dy_mm = 0.25

#-- 0.25mm/gu => 4 gu/mm. We need to define it to avoid floats
#-- in conversions
M2G = 4

#-- Our grid needs to be at least PE+a+Di+b+Di = 4+5+3+3+3 = 18mm
#-- in the x direction and 45mm in the y one.
#-- if our granularity will be 0.25mm/gu we will need at least 72g
#-- nx = 72 and ny = 170. Since we want the simulation from PE to our beam
#-- dump we will expand the grid until nx = 44.5cm = 446 mm = 1784 gu
NX = 1784
NY = 200

# ELECTRODES

Pr = 45                 # Outern radius of any electrode

# PE

PEri = 1.75             # PE hole initial radius in mm
PEro = 8.68             # PE hole final radius in mm
TAN60 = 1.73205080757   # tan(60)
#PEw = 4                 # PE width in mm
PEwall = 0              # PE wall to check if the field is the same. In mm


# PD
PDw = 3                 # D# width in mm
D4r = 2                 # D4 hole radius 
D5r = 2.5               # D5 hole radius
D6r = 3                 # D6 hole radius


  

#------------------------------ FUNCTIONS --------------------------------#

def gen_pa_name_from_data (PEwidth, dist1,
                           elec1, E1width, dist2,
                           elec2, E2width, dist3,
                           elec3, E3width ):
    '''  '{0:g}'.format(dist1) ensures not fixed point notation '''
    return 'rep_PE_w' + '{0:g}'.format(PEwidth) + \
           '_' + '{0:g}'.format(dist1) + \
           '_' + elec1 + '_w' + '{0:g}'.format(E1width) + \
           '_' + '{0:g}'.format(dist2) + \
           '_' + elec2 + '_w' + '{0:g}'.format(E2width) + \
           '_' + '{0:g}'.format(dist3) + \
           '_' + elec3 + '_w' + '{0:g}'.format(E3width) + '.pa#'

def create_path_from_filename (filename):
    return os.getcwd() + '\\pas\\' + filename[:-4] 


def gen_electrode_abs_pos (pa, geom, width, posx, elec_num):
    ''' # Name: gen_electrode_abs_pos (geom, width, posx, elec_num)
        # Inputs:
        #   pa: pa template to modify
        #   geom: Name of the geomtery of the electrode.
        #           PE: Plasma electrode.
        #           D4: Electrode with a hole of diameter = 4mm.
        #           D5: Electrode with a hole of diameter = 5mm.
        #           D6: Electrode with a hole of diameter = 6mm.
        #   posx: Absolute position of the starting of the electrode in the
        #           x axis in mm.
        #   elec_num: Electrode reference number for simulations
        # Outputs: The modified pa.
        # Description:
        #   Given a geometry of an electrode, its initial position and the
        #   electrode reference number, this function generates the mesh
        #   of the selected electrode, in the given position with the stated
        #   reference number.'''
    # PE geometry definition
    # The Plasma electrode has a hole in a cone shape
    # with a 60 degrees.
    # The remaining electrodes are just have a cylindrical hole.

    z = 0 # We don't need this parameter because our symmetry is cylindrical

    if geom == 'PE':
        # Generate the plasma potential
        for x in range(0, int(PEwall*M2G)):
            for y in range(0, Pr*M2G):
                pa.point(x, y, z, 1, elec_num)
        for x in range(posx*M2G, posx*M2G + width*M2G):
            for y in range(0, Pr*M2G):
                isinside = (y >= (x-PEwall)*TAN60 + PEri*M2G)
                if isinside:
                    pa.point(x, y, z, 1, elec_num)
    else:
        Dr = float(geom[1:])/2       # Extract the radius of the
                                    # electrode from the name.
        
        for x in range(int(posx*M2G), int(posx*M2G + width*M2G)):
            for y in range(0, Pr*M2G):
                inside = (y >= Dr*M2G) 
                if inside:
                    pa.point(x, y, z, 1, elec_num)
    return pa


def gen_set_electrodes (pa, width0,
                        dist1, elec1, width1,
                        dist2, elec2, width2,
                        dist3, elec3, width3):
    ''' # Name: gen_set_electrodes (pa, dist1, elec1,
                                        dist2, elec2,
                                        dist3, elec3)
        # Inputs:
        #   pa: pa template to modify
        #   dist1: Distance between PE and first electrode in mm.
        #   elec1: First electrode after the Plasma Electrode.
        #          it will be 'D4','D5','D6' or DN. Where:
        #           PE: Plasma electrode.
        #           D4: Electrode with a hole of diameter = 4mm.
        #           D5: Electrode with a hole of diameter = 5mm.
        #           D6: Electrode with a hole of diameter = 6mm.
        #           D#: Electrode with a hole of diameter = #mm.
        #   width1: Width of the first electrode in mm.
        #   dist2: Distance between first and second electrodes in mm.
        #   elec2: Second electrode. Similar to elec1.
        #   width2: Width of the second electrode in mm.
        #   dist3: Distance between second and third electrodes in mm.
        #   elec3: Third electrode. Similar to elec1.
        #   width3: Width of the third electrode in mm.
        # Outputs: The modified pa
        # Description:
        #   This script generates a set of electrodes starting with the Pwall+PE
        #   with width1 and following with elec1 at a dist1 distance with width2
        #   width. Then generates the second with the elec2 geometry at a dist2
        #   distance form the first one with width2. Finally, it generates the
        #   elec3 at dist3 distance from the second electrode with width3.
        #   The modified pa is returned'''
    # Generate the plasma electrode
    # 1st generate the wall
    pa = gen_electrode_abs_pos(pa, 'PE', width0, PEwall*M2G, 1)
    # When generate the electrodes we have to add PEwall to the dist1+PEw
    # because we have inserted the plasma potential model
    
    # Generate 1st electrode
    pa = gen_electrode_abs_pos(pa, elec1, width1,
                            (dist1+width0+PEwall)*1, 2)
    # Generate 2nd electrode
    pa = gen_electrode_abs_pos(pa, elec2, width2,
                            (dist1+width0+dist2+width1+PEwall)*1, 3)
    # Generate 3rd electrode
    pa = gen_electrode_abs_pos(pa, elec3, width3,
                            (dist1+width0+dist2+width1+dist3+width2+PEwall)*1, 4)

    # Genarate faraday cup end position electrode
    pa = gen_electrode_abs_pos(pa, 'D0', 1, NX/M2G-1, 5)

    return pa
    
def gen_electrodes_set_pa (dists, elecs, width, filename):
    #-- creating an array from scratch
    #-- NY and NY are defiend in ElecrtrodeGenLib.gen_electrode_set_width
    pa = PA(nx = NX, ny = NY, symmetry = 'cylindrical')

    # Generate a set of electrodes
    gen_set_electrodes (pa, width[0],
                        dists[0], elecs[0], width[1],
                        dists[1], elecs[1], width[2],
                        dists[2], elecs[2], width[3])

    #-- Save the mesh into a file
    path = create_path_from_filename (filename)
    create_folder_with_path (path)
    pa.save(path + "\\" + filename)


    



