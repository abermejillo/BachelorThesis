--[[
 solenoid_fe.lua

  original code from c-magnet@simion/examples/magentic_potential
  more info @ simion users discussion group 
  "Solenoid enclosed into a pure iron case"
  http://forum.simion.com/topic/1970-solenoid-enclosed-into-a-pure-iron-case/
--]]

simion.workbench_program()
simion.early_access(8.2) -- http://simion.com/info/early_access.html


-- USER defined params

  -- For SIMULATION
local DONOTPRESERVETRAJ = 1 --If true trajectories are NOT preserved.

  -- For LEBT
local RECALCAREA = true -- true if area needs to be recalculated
  -- default geometry params for two solenoids.
local g_geom_params1 = {6808.0100001022,3221,351,4269,999}
local g_geom_params2 = {6808.0100001022,5771,351,6819,999}
adjustable mu_inside = 3000           -- relative permeability of core.
adjustable coil_section = 5.5572   -- mm^2 = 10 AWG with insulator.
adjustable coil_section = 1   -- mm^2 = 17 approx AWG with insulator.
adjustable pack = 0.75  -- packing factor
adjustable x_width = 0 -- mm to add to solenoid widh.
                        -- Master solenoid has 155 mm.
adjustable y_height = 0 -- mm to add to solenoid height.
                        -- Master solenoid has 130 mm. Max 180 mm (PA limit)

  -- magnetic field measurement
local magxsol1 = 410.5
local magxsol2 = 736.5                        
-- adjustable magypos = 0.0
local MAG0 = 0.0
local MAGF = 40
local MAGSTEP = 41
  -- Faraday Cup
local fc_cy_mm = 0   -- FC center y axis in mm
local fc_cz_mm = 0   -- FC center z axis in mm
local faradaycuprmm = 2 -- Faraday cup (FC) radius in mm

-- Some user defined parameters are taken from  batch_config.csv
-- The values here are default ones.
  
  -- Set the number of simulations we want for each PA.
local num_runs = 0

  -- Reppeler electrode 
local ELECTRV0 = 4000     -- 3rd electrode initial voltage
local ELECTRVF = 4500     -- 3rd electrode final voltage
local ELECTRVSTEP = 500   -- 3rd electrode voltage increment step

  -- Plasma electrode
local plasmaelecvolt = 8000 -- plasma electrode voltage

  -- Ions created: At definition of particles we set the starting 
  -- point x_0. We need to set the same number to know if the 
  -- particle has been created or not.
local MIN_X = 0.01

  -- LEBT
adjustable SOL1I0 = 32500 -- A. Solenoid 1 initial total current.
adjustable SOL1IF = 32500 -- A. Solenoid 1 final total current.
adjustable SOL1ISTEP = 500 -- A. Solenoid 1 step total current.

adjustable SOL2I0 = 28500 -- A. Solenoid 2 initial total current.
adjustable SOL2IF = 28500 -- A. Solenoid 2 final total current.
adjustable SOL2ISTEP = 500 -- A. Solenoid 2 step total current.

-- END OF User defined parameters

-- granularity of the pa, it must be the same as the iob.
local dx_mm = 0.1

-- LEBT
-- g => global. Badly coded :(
adjustable gI1T = 0  --A. To store the solenoid total current.
adjustable gI2T = 0  --A. To store the solenoid 2 total current.
adjustable I1 = 0  --A. To store the solenoid 1 wire current.
adjustable I2 = 0  --A. To store the solenoid 2 wire current.
local turns1 = 0
local turns2 = 0
local lebt_start_mm = 238--mm. start position of the LEBT

-- Various arrays to store variables on each particle EMITTANCE 
local y0 = {}        -- y positions (mm)
local z0 = {}        -- z positions (mm)
local y0prime = {}   -- y' (radians)
local z0prime = {}   -- z' (radians)
local v0x = {}       -- x-velocity (mm/usec)
local v0y = {}       -- y-velocity (mm/usec)
local v0z = {}       -- z-velocity (mm/usec)


-- PEPPERPOTS
local peppers_width_mm = 35 -- Distance from pepper to scintillator.

--  PEPPER 1
-- Various arrays to store variables on each particle EMITTANCE 
local y1 = {}        -- y positions (mm)
local z1 = {}        -- z positions (mm)
local y1prime = {}   -- y' (radians)
local z1prime = {}   -- z' (radians)
local v1x = {}       -- x-velocity (mm/usec)
local v1y = {}       -- y-velocity (mm/usec)
local v1z = {}       -- z-velocity (mm/usec)
-- PEPPER 1 is centerd at the center of the cross
local pep1_start_mm = 556
local pep1_end_mm = pep1_start_mm + peppers_width_mm

--  PEPPER 2
-- Various arrays to store variables on each particle EMITTANCE 
local y2 = {}        -- y positions (mm)
local z2 = {}        -- z positions (mm)
local y2prime = {}   -- y' (radians)
local z2prime = {}   -- z' (radians)
local v2x = {}       -- x-velocity (mm/usec)
local v2y = {}       -- y-velocity (mm/usec)
local v2z = {}       -- z-velocity (mm/usec)
-- PEPPER 2 is at the splat electrode (end of simulation x axis)
local pep2_end_mm = 915.7 + 2*x_width
local pep2_start_mm = pep2_end_mm - peppers_width_mm

-- Faraday cup related
local ionsinfc = 0 -- Number of ions inside the FC in each run
                       
-- Beam loss calculation
local total_ions = 0 -- To calculate the # of ions actually generated.
local ions_outside_elecs = 0 -- # of ions that exit the electrode set.
local ions_outside_lebt = 0 -- # of ions that exit the lebt tube.

-- Absolute position of the end of the electrode set and lebt.
--  Used in order to calculate the emittance and the beam loss.
--  In this script the geomtries are fixed
local elec_end_mm = 65
local lebt_end_mm = 844.3 +2*x_width -- Nominal 832.3 mm.

-- Parameters for current run.
local thirdelecvolt -- 3rd electrode voltage
local results_file -- file to store the ions end position
local results_file_is -- file to store the ions end position
					  -- at the end of Ion Source.
                      

--Params for the .ion file
local speed_ion = 0 --To go from speed to KE
local KE_ion = 0 --To save KE
local AZ_ion = 0 --To save the AZ angle
local EL_ion = 0 --To save the EL angle


-- Stats results for all runs.
local all_results_file -- file to store all the stats.



-- Locate PA instances.
local muinst = simion.wb.instances[1]
local jzinst = simion.wb.instances[2]
local rAinst = simion.wb.instances[3]
local painst = simion.wb.instances[4]

-- Assign contour colors to specific PA instances for clearer visualization.
-- Maps color numbers of list of PA instance numbers.
simion.experimental.contour_color_instance{[1]={3}, [3]={1,2}, [10]={1}}

_G.x_width = x_width
_G.y_height = y_height

print("Performing gem2pa Az")
simion.command 'gem2pa solenoid_fe-Az.gem'
print("Loading solenoid_fe-Az.pa")
rAinst.pa:load("solenoid_fe-Az.PA")

  -- Accessing fields.
local A = simion.experimental.field_array{rA=rAinst}
local bfield = A.bfield
segment.mfield_adjust = simion.experimental.make_mfield_adjust(bfield)

-- Accessing fields.
-- local A = simion.experimental.field_array{rA=rAinst}
-- local bfield = A.bfield
-- segment.mfield_adjust = simion.experimental.make_mfield_adjust(bfield)

------------------------- OPEN CSV WRITE ---------------------------
-- Open file for record data and write header
-- parameters:
--  file: string with the name of the file.
--  path: string with the path of the file.
--  header: string with the header of the file.
function opencsvforwrite (file, path, header)
  file = assert(io.open(path, "w")) 
  file:write(header)  
  return file
end

------------------------- CSV PARSER -------------------------------
-- Parse the csv in the current folder with name batch_config.csv
-- parameters:
--   path: string with the path of the file to read.
function read_csv_file(path)
    local file = io.open(path, "r") -- r read mode and b binary mode
    --if not file then return nil end
    local data = {}
    for line in io.lines(path) do
      -- Check if the line is not empty or a comment (starts with #).
      if line ~= '' and string.sub(line,1,1) ~= '#' then
        -- Extract the info from the line.
        local plasma_volt,
        elec_init_volt,
        elec_end_volt,
        elec_step_volt,
        sol1_init_total_A,
        sol1_end_total_A,
        sol1_step_total_A,
        sol2_init_total_A,
        sol2_end_total_A,
        sol2_step_total_A = line:match("([^,]*),([^,]*),([^,]*),([^,]*)" ..
                            ",([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")
        -- Update the data table with the new info.
        data[#data+1] = {plasma_volt = tonumber(plasma_volt), 
                        elec_init_volt = tonumber(elec_init_volt), 
                        elec_end_volt = tonumber(elec_end_volt),
                        elec_step_volt = tonumber(elec_step_volt),
                        sol1_init_total_A = tonumber(sol1_init_total_A),
                        sol1_end_total_A = tonumber(sol1_end_total_A),
                        sol1_step_total_A = tonumber(sol1_step_total_A),
                        sol2_init_total_A = tonumber(sol2_init_total_A),
                        sol2_end_total_A = tonumber(sol2_end_total_A),
                        sol2_step_total_A = tonumber(sol2_step_total_A),}
      end
    end
    file:close()
    return data
end

------------------- RMS STD DEV VELOCITY--------------------------
-- Compute rms and variance of the velocity given a verctor
function compute_rms_stdev (v)
  local rms = 0
  local avg = 0
  local stdev = 0
  for _,a in ipairs(v) do
    rms = rms + a*a
    avg = avg + a
  end
  if #v ~= 0 then 
    rms = sqrt(rms / #v) 
    avg = avg/ #v
  end
  print ("avg: " .. avg)
  return rms 
end

------------------ GENERATE LOAD AND REFINE PA --------------------
-- Generate a PA taking into account the enlargement of the solenoids
-- parameters:
--   x_width - mm to add to solenoid widht.
function generate_load_refine_pa(x_width)
    print("Generating electrode related pa")
    print("  Returns: " .. os.execute("python gen_pit30_einzel.py " .. 
                                       x_width .. " " .. y_height))
    print("0 menans all Ok. Otherwise an error ocurred.")
    -- Load pa
    pafilepath = "pas\\rep_PE_w4_32_D11_w4_7_D12_w8_6_D10_w4\\"
    pafilename = pafilepath .. "rep_PE_w4_32_D11_w4_7_D12_w8_6_D10_w4.pa#"
    print("Loading pa")
    painst.pa:load(pafilename)
    painst:_debug_update_size()
      -- update PA instance in case size changed (TODO: shouldn't be necessary)
    simion.redraw_screen()
    -- Refine pa
    print("Refining pa")
    painst.pa:refine{
     convergence=convergence
     --removed:  , skipped_point=rebuild 
    }
  end

------------------------- EMITTANCE -------------------------------
-- Compute y-emittance from points in phase space.
-- parameters:
--   y - array of y points (mm)
--   yprime - array of angles (radians)
--   vx - array of x-velocities
--   vy - array of y-relocities
-- returns
--   emit - emittance
--   norm_emit - normalized emittance
function compute_emittance(y, yprime, vx, vy)
    -- Compute average of all numbers in given array.
    -- Returns 0 if array contains zero elements.
    function average(array)
        local result = 0
        for _,a in ipairs(array) do result = result + a end
        if #array ~= 0 then result = result / #array end
        return result
    end

    -- Compute various averages for emittance.
    local y_ave = average(y)
    local yprime_ave = average(yprime)
    local t = {}; for n = 1,#y do t[n] = (y[n] - y_ave)^2 end
    local dy2_ave = average(t)
    local t = {}; for n = 1,#y do t[n] = (yprime[n] - yprime_ave)^2 end
    local dyprime2_ave = average(t)
    local t = {}; for n = 1,#y do t[n] = (y[n]-y_ave)*(yprime[n]-yprime_ave) end
    local dy_dyprime_ave = average(t)

    -- Compute emittance from averages, in correct units.
    local m = dy2_ave * dyprime2_ave - dy_dyprime_ave^2
    if m < 0 then m = 0 end      -- safety on numerical roundoff
    local emit = sqrt(m) * 1000  -- (mm * mrad)

    -- Compute average speed for normalized emittance.
    local vx_avg = average(vx)
    local vy_avg = average(vy)
    local v_avg = sqrt(vx_avg^2 + vy_avg^2)
    --FIX: or this:
    --local t = {}; for n = 1,#y do t[n] = sqrt(vx[n]^2 + vy[n]^2) end
    --local v_avg = average(t)

    -- compute normalized emittance from averages
    local c = 300000                    -- speed of light (mm/usec)
    local beta = v_avg / c              -- relativistic beta
    local gamma = 1 / sqrt(1 - beta^2)  -- relativistic gamma
    local norm_emit = beta * gamma * emit

    return emit, norm_emit   
end

function reset_emittance_params ()
     -- Empty emittance arrays for the simulation
     -- PEPPER 1
  y0 = {}        -- y positions (mm)
  z0 = {}        -- z positions (mm)
  y0prime = {}   -- y' (radians)
  z0prime = {}   -- z' (radians)
  v0x = {}       -- x-velocity (mm/usec)
  v0y = {}       -- y-velocity (mm/usec)
  v0z = {}       -- z-velocity (mm/usec)
     -- PEPPER 1
  y1 = {}        -- y positions (mm)
  z1 = {}        -- z positions (mm)
  y1prime = {}   -- y' (radians)
  z1prime = {}   -- z' (radians)
  v1x = {}       -- x-velocity (mm/usec)
  v1y = {}       -- y-velocity (mm/usec)
  v1z = {}       -- z-velocity (mm/usec)
    
    -- PEPPER 2
  y2 = {}        -- y positions (mm)
  z2 = {}        -- z positions (mm)
  y2prime = {}   -- y' (radians)
  z2prime = {}   -- z' (radians)
  v2x = {}       -- x-velocity (mm/usec)
  v2y = {}       -- y-velocity (mm/usec)
  v2z = {}       -- z-velocity (mm/usec)
end

------------------------- LEBT FUNCS -----------------------------------

-- Rescale potential given a rectangular area. 
-- Scale has the same syntax as potentials_scale
-- and the area, the same as a box in GEM syntax.
local function potentials_scale_box (inst, a, b, xo, yo, xf, yf)
  for xi,yi,zi in inst.pa:points() do
    if xi >= xo and xi <=xf and yi >= yo and yi <= yf then
      local v = inst.pa:potential(xi,yi,zi)
      inst.pa:potential(xi,yi,zi, a + b*v)
    end
  end
  return inst 
end


-- Finds area (mm^2) in 2D PA instance having given value v.
-- It supposes that the area is rectangular and returns also
-- the two vertices as a box GEM syntax.
local function find_area(inst, v)
  local area = 0
  local dA = inst.pa.dx_mm * inst.scale * inst.pa.dy_mm * inst.scale
  local x_min = math.huge
  local x_max = 0
  local y_min = math.huge
  local y_max = 0
  for x,y,z in inst.pa:points() do
    if inst.pa:potential(x,y,z) == v then
      -- print ("x: " .. x .. ",y: " .. y .. ",z: " .. z)
      area = area + dA 
      if x*y < x_min * y_min then
        x_min = x
        y_min = y
      elseif x*y > x_max * y_max then
        x_max = x
        y_max = y
      end 
    end
  end
  return area, x_min, y_min, x_max, y_max
end


local function jfield(x,y,z)
  return 0,0,jzinst:potential_wc(x,y,z)
end

-- ####################### PROGRAM STRATS ###################### --

------------------ GENERATE LOAD AND REFINE PA --------------------
generate_load_refine_pa(x_width)

--------------------- PARSE BATCH CONFIG --------------------------
-- Parse batch_config.csv file into a table and set some params
local data = read_csv_file("batch_config.csv")

--------------------- CREATE STATS FILE --------------------------
-- Create the file to store all the relevant params.
    statallpath = "stats\\stats_" .. os.date("%Y%m%H%M%S") .. ".csv"
    statallheader =  "plasmaevolt (V),extractevolt(V),"..
                     "width (mm),height(mm),"..
                     "sol1ITotal(A),sol1I (A),sol1Turns,"..
                     "sol2ITotal(A),sol2I (A),sol2Turns,"..
                     "lebt_emitt_y (mm*mrad),lebt_norm_emitt_y (mm*mrad),"..
                     "lebt_emitt_z (mm*mrad),lebt_norm_emitt_z (mm*mrad),"..
                     "pep1_emitt_y (mm*mrad),pep1_norm_emitt_y (mm*mrad),"..
                     "pep1_emitt_z (mm*mrad),pep1_norm_emitt_z (mm*mrad),"..
                     "pep2_emitt_y (mm*mrad),pep2_norm_emitt_y (mm*mrad),"..
                     "pep2_emitt_z (mm*mrad),pep2_norm_emitt_z (mm*mrad),"..
                     -- "pep1_vel_rms_y,pep1_vel_stdev_y,"..
                     -- "pep1_vel_rms_z,pep1_vel_stdev_z,"..
                     "lebt_vel_rms_y,lebt_vel_rms_z,"..
                     "pep1_vel_rms_y,pep1_vel_rms_z,"..
                     "#parts created,#parts end elecs,#parts end lebt,"..
                     "beam loss elecs(%),beam_loss_lebt (%),"..
                     "beam loss total(%),#parts in FC\n"
    all_results_file=opencsvforwrite (all_results_file, statallpath,statallheader)


------------------------- FLYM ------------------------------------

function segment.flym()
  sim_trajectory_image_control = DONOTPRESERVETRAJ -- don't preserve trajectories
  --sim_trajectory_image_control = 0 -- do preserve trajectories
  sim_trajectory_quality = 0 -- fastest trajectory integration
  
  local nv1 = 1     -- The potential asigned in the -jz GEM file to 
                      -- the non-pole associated to the 1st solenoid.
                      
  local nv2 = 1.001 -- The potential asigned in the -jz GEM file to 
                      -- the non-pole associated to the 2nd solenoid.
  
  -- Initialize the geomatries to the ones precalculated  
  local geom_params1 = g_geom_params1
  local geom_params2 = g_geom_params2
  
  print('Performing gem2pa')
  
  _G.x_width = x_width
  _G.y_height = y_height
  
  -- simion.command 'gem2pa solenoid_fe-Az.gem'
  simion.command 'gem2pa solenoid_fe-mu.gem'
  simion.command 'gem2pa solenoid_fe-jz.gem'
  
  -- rAinst.pa:load("solenoid_fe-Az.PA")
  
    -- -- Accessing fields.
  -- local A = simion.experimental.field_array{rA=rAinst}
  -- local bfield = A.bfield
  -- segment.mfield_adjust = simion.experimental.make_mfield_adjust(bfield)

  -- (optional) Rescale permeabilities based on "mu" variable.
  print('Rescaling permeabilities')
  muinst.pa:load("solenoid_fe-mu.PA")
  for x,y,z in muinst.pa:points() do
    local mu = muinst.pa:potential(x,y,z)
    mu = (mu == 1) and 1 or mu_inside --if mu == 1 mu=1 else mu = mu_inside
    muinst.pa:potential(x,y,z, mu)
  end
  
  -- LEBT 
  jzinst.pa:load("solenoid_fe-jz.PA")
  
  if RECALCAREA then
              
    geom_params1 = {find_area(jzinst, nv1)}; 
    print('area 1 (mm^2)=' .. geom_params1[1] ..
          ', x_min = ' .. geom_params1[2] ..
          ', y_min = ' .. geom_params1[3] ..
          ', x_max = ' .. geom_params1[4] ..
          ', y_max = ' .. geom_params1[5] )
    
    print ("geom_params1[1]: " .. geom_params1[1])  
    
    geom_params2 = {find_area(jzinst, nv2)}; 
    print('area 2 (mm^2)=' .. geom_params2[1] ..
          ', x_min = ' .. geom_params2[2] ..
          ', y_min = ' .. geom_params2[3] ..
          ', x_max = ' .. geom_params2[4] ..
          ', y_max = ' .. geom_params2[5] )
     
  -- else 
    -- We already know the geometry so we detect the exact nv1 and nv2
    -- from the jzinst.
    -- jzinst.pa:load()
    -- Already init. geom_params1 = g_geom_params1
    -- nv1 = jzinst.pa:potential(350,90,90) -- we know that 350,90,90
                                         -- is a point inside the 1st solenoid
    -- Already init. geom_params2 = g_geom_params2
    -- nv2 = jzinst.pa:potential(600,90,90) -- we know that 600,90,90
                                         -- is a point inside the 2nd solenoid
  end
  
  -- IN THIS SCRIPT THE SOLENOIDS GEOM IS NOT VARIABLE SO WE ONLY
  -- ITERATE THE FOLLOWING:
  -- Update simulation params Start cycling from PA to PA.
  for _, datum in ipairs(data) do
    plasmaelecvolt = 8000--datum.plasma_volt -- plasma electrode voltage
    ELECTRV0 = 4000--datum.elec_init_volt     -- 3rd electrode initial voltage
    ELECTRVF = 4000--datum.elec_end_volt     -- 3rd electrode final voltage
    ELECTRVSTEP = 0--datum.elec_step_volt   -- 3rd electrode voltage step
    SOL1I0 = 32500--datum.sol1_init_total_A --Solenoid 1 initial total current in A
    SOL1IF = 32500--datum.sol1_end_total_A --Solenoid 1 final total current in A
    SOL1ISTEP = 0--datum.sol1_step_total_A --Solenoid 1 step total current in A
    SOL2I0 = 1000--datum.sol2_init_total_A --Solenoid 2 initial total current in A
    SOL2IF = 1000--datum.sol2_end_total_A --Solenoid 2 final total current in A
    SOL2ISTEP = 0--datum.sol2_step_total_A --Solenoid 2 step total current in A
    
    for I1T = SOL1I0, SOL1IF, SOL1ISTEP do
      -- Each time it enters here it will be the first for 
      -- the following for loop
      gI1T = I1T
      local first_iteration = true
                                  
      for I2T = SOL2I0, SOL2IF, SOL2ISTEP do
        gI2T = I2T
          -- Check if we have the pas already claculated
        magfolderpath = "pas\\mag\\w"..x_width.."_".. "h"..y_height..
                        "_"..I1T.."_"..I2T
          -- mkdir returns 0 if new folder.
        --magfolderpath = "pas\\mag\\17500_28500"
        itexists = os.execute( "mkdir " .. magfolderpath )
        print ("op: " .. itexists)
        if  itexists == 0 then 
          jzinst.pa:load("solenoid_fe-jz.PA") -- Load original before reescaling.
          -- We need to calculate here in order to check first if we have the 
          -- pas already calulated and avoid the coil 1 unnecessary calculations.
          --print ("I1T: "..I1T)
          -- Rescale currents based on "I" variable.
          print('Rescaling currents')
          turns1 = geom_params1[1]*pack/coil_section    -- Solenoid 1 turns.
          I1 = I1T/turns1
          --print ('Coil 1 current (A): ' .. I1 .. ', Turns: ' .. turns1)
          -- Precalculated local nv1 = 1      
          jzinst = potentials_scale_box(jzinst,0, I1T/nv1/geom_params1[1],
                                        geom_params1[2],
                                        geom_params1[3],
                                        geom_params1[4],
                                        geom_params1[5])
                                      
          --print ("I2T: "..I2T)
          -- Precalculated local nv2 = 1.001
          jzinst = potentials_scale_box(jzinst,0, I2T/nv2/geom_params2[1],
                                        geom_params2[2],
                                        geom_params2[3],
                                        geom_params2[4],
                                        geom_params2[5])
          
          turns2 = geom_params2[1]*pack/coil_section    -- Solenoid 2 turns.
          I2 = I2T/turns2 
          --print ('Coil 2 current (A): ' .. I2 .. ', Turns: ' .. turns2)

          -- Solve field.
          print('Solving field')
          rAinst.pa:refine{potential_type='magnetic[r*A]',
              charge=jzinst.pa,
              permeability=muinst.pa,
              convergence=1e-6}
          
          simion.redraw_screen()
          
          -- Save the pas for future calculations
          -- magfolderpath = "pas\\mag\\"..I1T.."_"..I2T
          rAinst.pa:save(magfolderpath .. "\\rAinst.pa")
          muinst.pa:save(magfolderpath .. "\\muinst.pa")
          jzinst.pa:save(magfolderpath .. "\\jzinst.pa")
          
          
        else
          print ("geom_params1[1]: " .. geom_params1[1])
          turns1 = geom_params1[1]*pack/coil_section    -- Solenoid 1 turns.
          I1 = I1T/turns1
          print ('Coil 1 current (A): ' .. I1 .. ', Turns: ' .. turns1)
          turns2 = geom_params2[1]*pack/coil_section   -- Solenoid 2 turns.
          I2 = I2T/turns2 
          --print ('Coil 2 current (A): ' .. I2 .. ', Turns: ' .. turns2)
          rAinst.pa:load(magfolderpath .. "\\rAinst.pa")
          muinst.pa:load(magfolderpath .. "\\muinst.pa")
          jzinst.pa:load(magfolderpath .. "\\jzinst.pa")
        end 
        -- Plot.
        -- local CON = simion.import './contour/contourlib81.lua'
        -- CON.plot {func=bfield, mark=true, npoints=60, z=0}
        -- CON.plot{func=bfield, npointsx=20, npointsy=20, mark=true, z=0}
        -- CON.plot{func=jfield, npoints=60, mark=true, z=0}
        
        -- MAGNETIC FILED MEASUREMENT

        magfilepath = "recordings\\mag_" .. x_width .. "_" .. y_height ..  
                      "_" .. magxsol1 .. "_" .. magxsol2 .. "_" .. I1T .. 
                      "_" .. I2T .. ".csv"
        magfileheader = "ypos @ ".. magxsol1 .." (mm),B-field (Gauss),"..
                        "ypos @ ".. magxsol2 .." (mm),B-field (Gauss)\n"
        magnetic_file=opencsvforwrite (magnetic_file, magfilepath, magfileheader)
        for magypos = MAG0, MAGF, MAGSTEP do
          magnetic_file:write(magypos..","..bfield(magxsol1,magypos,0)..","..
                              magypos..","..bfield(magxsol2,magypos,0) .. "\n")
        end
        magnetic_file:close()
                            
        print ("Magnetic fields at several points")
		print('B-field (Gauss) at (60,0,0) mm (out Einzel):', bfield(60,0,0))
		print('B-field (Gauss) measured at (430,0,0) mm (sol1):', bfield(430,0,0))
        print('B-field (Gauss) at (600,0,0) mm (mid solenoids) :', bfield(600,0,0))
		print('B-field (Gauss) at (770,0,0) mm (sol2):', bfield(770,0,0))
		print('B-field (Gauss) at (915,0,0) mm: (pep2)', bfield(915,0,0))
        
        -- ELECTRODES
        for el = ELECTRV0, ELECTRVF, ELECTRVSTEP do -- iterate electrode 
          print ("\nel: ".. el .. ", I1T: " .. I1T .. ", I2T: " .. I2T)
          thirdelecvolt = el
          -- Create a file to record the ions' end position
          recpath = "recordings\\rec"..
                    "_"..plasmaelecvolt..
                    "_"..thirdelecvolt..
                    "_"..x_width..
                    "_"..y_height..
                    "_"..I1T.."_"..I2T..".csv"
          recheader = "PE (V):"..plasmaelecvolt..
                      ", 3rd Electrode (V):".. thirdelecvolt..
                      ", x_width (mm):" .. x_width ..
                      ", y_height (mm):" .. y_height ..
                      ", 1st Solenoid wire current (A):".. I1.. 
                      ", 2st Solenoid wire current (A):".. I2.."\n".. 
                      "ion#, endposx (mm), endposy (mm), endposz (mm), "..
                      "endvelx (mm/usec), endvely (mm/usec), endvelz (mm/usec)\n"
          results_file = opencsvforwrite (results_file, recpath,recheader)
		  recpath_is = "recordings\\rec_is"..
                    "_"..plasmaelecvolt..
                    "_"..thirdelecvolt..
                    "_"..x_width..
                    "_"..y_height..
                    "_"..I1T.."_"..I2T..".csv"
		  results_file_is = opencsvforwrite (results_file_is, recpath_is,recheader)
		  recpath_pep1 = "recordings\\rec_pep1"..
                    "_"..plasmaelecvolt..
                    "_"..thirdelecvolt..
                    "_"..x_width..
                    "_"..y_height..
                    "_"..I1T.."_"..I2T..".csv"
		  results_file_pep1 = opencsvforwrite (results_file_pep1, recpath_pep1,recheader)
		  recpath_pep2 = "recordings\\rec_pep2.csv"
		  results_file_pep2 = opencsvforwrite (results_file_pep2, recpath_pep2,recheader)
          painst.pa:fast_adjust{[1]=plasmaelecvolt, [2]=0, [3]=thirdelecvolt, 
                                [4]=0, [5]=0, [6]=0}
          run ()
        end
        -- Close file ion's position file
        results_file:close()
		results_file_is:close()
		results_file_pep1:close()
		results_file_pep2:close()
      end
    end
  end  
  all_results_file:close()
  --print ("num_runs: "..num_runs)
end

------------------------- INITR -----------------------------------
function segment.initialize_run()
  -- Initialize parameters for current run.
  
    -- Empty emittance arrays for the simulation
  reset_emittance_params ()
  
    -- reset total_ions and ions_outside_elecs for the run
  total_ions = 0 
  ions_outside_elecs = 0
  ions_outside_lebt = 0
  ionsinfc = 0 -- Initialize to 0 the number of ions inside the FC in this run
  
  num_runs = num_runs + 1

end

------------------------- EVERY TIME ------------------------------
-- SIMION segment called on every time-step
function segment.other_actions()
  --prevent more than one execution
  -- http://forum.simion.com/topic/1788-the-segments-execute-twice-if-magpa-was-added/?tab=comments#comment-7068
  if ion_instance ~= 4 then 
      return end
  if ion_mass < 1   then return end -- skip if not ion (amu < 1)
  --if ion_splat == 0 then return end -- skip if ion not yet splatted.
  -- Particle in LEBT
  if ((ion_px_mm > lebt_start_mm) and (ion_px_mm < (lebt_start_mm + dx_mm))) then
    -- store variables for emittance calculation
    --print ("ion_number: "..ion_number.." ion_px_mm: "..ion_px_mm)
    local particle_count0 = #y0 + 1
    y0[particle_count0] = ion_py_mm    -- store y position (mm)
    z0[particle_count0] = ion_pz_mm    -- store z position (mm)
    v0x[particle_count0] = ion_vx_mm   -- store x-velocity (mm/usec)
    v0y[particle_count0] = ion_vy_mm   -- store y-velocity (mm/usec)
    v0z[particle_count0] = ion_vz_mm   -- store z-velocity (mm/usec)
    y0prime[particle_count0] = ion_vy_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    z0prime[particle_count0] = ion_vz_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    -- FIX? or this: yprime[particle_count] = atan2(ion_vy_mm, ion_vx_mm)
	speed_ion = sqrt(ion_vx_mm*ion_vx_mm + ion_vy_mm*ion_vy_mm + ion_vz_mm*ion_vz_mm)
	r_ion, AZ_ion, EL_ion = rect3d_to_polar3d( ion_vx_mm, ion_vy_mm, ion_vz_mm )
	KE_ion = speed_to_ke(speed_ion,ion_mass)
	results_file_is:write(ion_time_of_birth .. "," .. ion_mass ..
                                        	"," .. ion_charge ..
						"," .. ion_px_mm ..
						"," .. ion_py_mm ..
						"," .. ion_pz_mm ..
						"," .. AZ_ion .. 
						"," .. EL_ion ..
						"," .. KE_ion ..
						"," .. ion_cwf ..
						"," .. ion_color .."\n")
    results_file_is:flush()  -- immediately output to disk
  
  -- Particle in PEPPER 1 scintillator position
  elseif ((ion_px_mm > pep1_end_mm) and (ion_px_mm < (pep1_end_mm + dx_mm))) then
    -- store variables for emittance calculation
    --print ("ion_number: "..ion_number.." ion_px_mm: "..ion_px_mm)
    --print ("ion_number: "..ion_number.." ion_vy_mm (mm/usec): "..ion_vy_mm)
    local particle_count1 = #y1 + 1
    y1[particle_count1] = ion_py_mm    -- store y position (mm)
    z1[particle_count1] = ion_pz_mm    -- store z position (mm)
    v1x[particle_count1] = ion_vx_mm   -- store x-velocity (mm/usec)
    v1y[particle_count1] = ion_vy_mm   -- store y-velocity (mm/usec)
    v1z[particle_count1] = ion_vz_mm   -- store z-velocity (mm/usec)
    y1prime[particle_count1] = ion_vy_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    z1prime[particle_count1] = ion_vz_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    -- FIX? or this: yprime[particle_count] = atan2(ion_vy_mm, ion_vx_mm)
	
	speed_ion = sqrt(ion_vx_mm*ion_vx_mm + ion_vy_mm*ion_vy_mm + ion_vz_mm*ion_vz_mm)
	r_ion, AZ_ion, EL_ion = rect3d_to_polar3d( ion_px_mm, ion_py_mm, ion_pz_mm )
	KE_ion = speed_to_ke(speed_ion,ion_mass)
	results_file_pep1:write( ion_number .. "," .. ion_px_mm ..
                                   "," .. ion_py_mm ..
                                   "," .. ion_pz_mm ..
                                   "," .. ion_vx_mm ..
                                   "," .. ion_vy_mm ..
                                   "," .. ion_vz_mm .."\n")
    results_file_pep1:flush()  -- immediately output to disk
    
  -- Particle in PEPPER 2 scintillator position
   elseif ((ion_px_mm > lebt_end_mm) and (ion_splat ~= 0)) then
	
    local particle_count2 = #y2 + 1
    y2[particle_count2] = ion_py_mm    -- store y position (mm)
    z2[particle_count2] = ion_pz_mm    -- store z position (mm)
    v2x[particle_count2] = ion_vx_mm   -- store x-velocity (mm/usec)
    v2y[particle_count2] = ion_vy_mm   -- store y-velocity (mm/usec)
    v2z[particle_count2] = ion_vz_mm   -- store z-velocity (mm/usec)
    y2prime[particle_count2] = ion_vy_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    z2prime[particle_count2] = ion_vz_mm / ion_vx_mm  -- store ~tan(theta) (rad)
    results_file_pep2:write( ion_number .. "," .. ion_px_mm ..
                                   "," .. ion_py_mm ..
                                   "," .. ion_pz_mm ..
                                   "," .. ion_vx_mm ..
                                   "," .. ion_vy_mm ..
                                   "," .. ion_vz_mm .."\n")
    results_file_pep2:flush()  -- immediately output to disk 
  end
end

------------------------- TERM ------------------------------------------------
function segment.terminate()
  -- Record some metric for each particle splat.
  --prevent more than one execution
  -- http://forum.simion.com/topic/1788-the-segments-execute-twice-if-magpa-was-added/?tab=comments#comment-7068
  if ion_instance ~= 4 then 
      return end

  results_file:write(ion_number .. "," .. ion_px_mm ..
                                   "," .. ion_py_mm ..
                                   "," .. ion_pz_mm ..
                                   "," .. ion_vx_mm ..
                                   "," .. ion_vy_mm ..
                                   "," .. ion_vz_mm .."\n")
  results_file:flush()  -- immediately output to disk
  
  -- Check the number of ions actually created.
  if ion_px_mm > MIN_X then -- minimum x (fits with the fly2 file). 
    total_ions = total_ions + 1
  end
  -- Check the number of ions that exit the electrodes
  if ion_px_mm > elec_end_mm then
    ions_outside_elecs = ions_outside_elecs + 1
  end  
  -- Check the number of ions that exit the lebt
  if ion_px_mm > lebt_end_mm then
    ions_outside_lebt = ions_outside_lebt + 1
    
    -- Check if the ion is inside the FC
    ionr2 = (ion_py_mm - fc_cy_mm)^2+(ion_pz_mm - fc_cz_mm)^2
    if ionr2 <= faradaycuprmm^2 then
      ionsinfc = ionsinfc + 1
    end
    
  end
end


------------------------- TERMR -----------------------------------------------          
function segment.terminate_run()
  -- Compute and store results for current run

  -- Emittance calcs --
  -- calculate/display emittance
  -- LEBT start
  --print("Num of particles for emittance calculation lebt start = " .. #y0)
  local emit_y0, norm_emit_y0 = compute_emittance(y0, y0prime, v0x, v0y)
  --print("Beam Emittance y = " .. emit_y0 .. " mm * mrad (Norm = " .. norm_emit_y0 .. ")")
  local emit_z0, norm_emit_z0 = compute_emittance(z0, z0prime, v0x, v0z)
  --print("Beam Emittance z = " .. emit_z0 .. " mm * mrad (Norm = " .. norm_emit_z0 .. ")")
  
  -- PEPPER 1
  --print("Num of particles for emittance calculation pepper 1 = " .. #y1)
  local emit_y1, norm_emit_y1 = compute_emittance(y1, y1prime, v1x, v1y)
  --print("Beam Emittance y = " .. emit_y1 .. " mm * mrad (Norm = " .. norm_emit_y1 .. ")")
  local emit_z1, norm_emit_z1 = compute_emittance(z1, z1prime, v1x, v1z)
  --print("Beam Emittance z = " .. emit_z1 .. " mm * mrad (Norm = " .. norm_emit_z1 .. ")")

  -- SPEED RMS AT LEBT
  local v_rms_y0 = compute_rms_stdev (v0y)
  --print ("Speed rms y = " .. v_rms_y1  )
  local v_rms_z0 = compute_rms_stdev (v0z)
  --print ("Speed rms z = " .. v_rms_z1 ) 
 
  -- SPEED RMS AT PEPPER 1
  local v_rms_y1 = compute_rms_stdev (v1y)
  --print ("Speed rms y = " .. v_rms_y1  )
  local v_rms_z1 = compute_rms_stdev (v1z)
  --print ("Speed rms z = " .. v_rms_z1 )
  
   -- PEPPER 2
  --print("Num of particles for emittance calculation pepper 2 = " .. #y2)
  local emit_y2, norm_emit_y2 = compute_emittance(y2, y2prime, v2x, v2y)
  --print("Beam Emittance y = " .. emit_y2 .. " mm * mrad (Norm = " .. norm_emit_y2 .. ")")
  local emit_z2, norm_emit_z2 = compute_emittance(z2, z2prime, v2x, v2z)
  --print("Beam Emittance z = " .. emit_z2 .. " mm * mrad (Norm = " .. norm_emit_z2 .. ")")
  
  -- optionally pause to show results
  --simion.sleep(2)  -- sec
     
  -- beam loss calc --
  local beam_loss_elec = (total_ions - ions_outside_elecs)*100/total_ions
  local beam_loss_lebt = (ions_outside_elecs - ions_outside_lebt)*100/ions_outside_elecs
  local beam_loss_total = (total_ions - ions_outside_lebt)*100/total_ions
  --print ("Total ions created: "..total_ions)
  --print ("Beam loss at electrodes(%): "..beam_loss_elec)
  --print ("Total ions at electrodes output: "..ions_outside_elecs)
  --print ("Beam loss at lebt(%): "..beam_loss_lebt)
  --print ("Total ions at lebt output: "..ions_outside_lebt)
  --print ("Beam loss total(%): "..beam_loss_total)
  --print ("Solenoid 1 total current (A): ".. gI1T)
  --print ("Solenoid 2 total current (A): ".. gI2T)

  -- Save the results of the current run --
  all_results_file:write(plasmaelecvolt..","..thirdelecvolt..","..
                         x_width..","..y_height..","..
                         gI1T..","..I1..","..turns1..","..
                         gI2T..","..I2..","..turns2..","..
                         emit_y0..","..norm_emit_y0..","..
                         emit_z0..","..norm_emit_z0..","..
                         emit_y1..","..norm_emit_y1..","..
                         emit_z1..","..norm_emit_z1..","..
                         emit_y2..","..norm_emit_y2..","..
                         emit_z2..","..norm_emit_z2..",".. 
                         -- v_rms_y1..","..v_stdev_y1..","..
                         -- v_rms_z1..","..v_stdev_z1..","..
                         v_rms_y0..","..v_rms_z0..","..
                         v_rms_y1..","..v_rms_z1..","..
                         total_ions..","..ions_outside_elecs..","..
                         ions_outside_lebt..","..beam_loss_elec..","..
                         beam_loss_lebt..","..beam_loss_total..","..
                         ionsinfc.."\n")

end