-- field_array.lua - SIMION workbench program that incorporates
-- magnetic field from data file into workbench.
--
-- The workbench must contain an empty magnetic PA instance
-- in which to apply this magnetic field.
--
-- Note: the data file solenoid.csv was originally generated
-- from the makefile.lua batch mode program.
--
-- D.Manura, 2007-03
-- (c) 2007 Scientific Instrument Services, Inc. (Licensed under SIMION 8.0)

simion.workbench_program()

-- Load field interpolation support.
local FieldArray = require "simionx.FieldArray"

-- Load solenoid field from data file.
local field1 = FieldArray("SNIF-8A_notapes_onlyfield_init.csv")
local field2 = FieldArray("SNIF-8A_notapes_onlyfield.csv")


-- granularity of the pa, it must be the same as the iob.
local dx_mm = 1.0
local lebt_start_mm = 238--mm. start position of the LEBT
adjustable x_width = 0 -- mm to add to solenoid widh.
                        -- Master solenoid has 155 mm.
adjustable y_height = 0 -- mm to add to solenoid height.
                        -- Master solenoid has 130 mm. Max 180 mm (PA limit)
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
local pep2_end_mm = 916 + 2*x_width
local pep2_start_mm = pep2_end_mm - peppers_width_mm

-- Absolute position of the end of the lebt
local lebt_end_mm = 844 +2*x_width -- Nominal 832.3 mm.

-- Stats results for all runs.
local all_results_file -- file to store all the stats.

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

--------------------- CREATE STATS FILE --------------------------
-- Create the file to store all the relevant params.
    statallpath = "stats\\stats_" .. os.date("%Y%m%H%M%S") .. ".csv"
    statallheader =  "lebt_emitt_y (mm*mrad),lebt_norm_emitt_y (mm*mrad),"..
                     "lebt_emitt_z (mm*mrad),lebt_norm_emitt_z (mm*mrad),"..
                     "pep1_emitt_y (mm*mrad),pep1_norm_emitt_y (mm*mrad),"..
                     "pep1_emitt_z (mm*mrad),pep1_norm_emitt_z (mm*mrad),"..
                     "pep2_emitt_y (mm*mrad),pep2_norm_emitt_y (mm*mrad),"..
                     "pep2_emitt_z (mm*mrad),pep2_norm_emitt_z (mm*mrad),"..
                     -- "pep1_vel_rms_y,pep1_vel_stdev_y,"..
                     -- "pep1_vel_rms_z,pep1_vel_stdev_z,"..
                     "lebt_vel_rms_y,lebt_vel_rms_z,"..
                     "pep1_vel_rms_y,pep1_vel_rms_z\n"
    all_results_file = opencsvforwrite (all_results_file, statallpath,statallheader)






-- Override magnetic field in magnetic PA instances
-- with that in the field array.
function segment.mfield_adjust()
	if ion_instance == 1 then 
       ion_bfieldx_gu, ion_bfieldy_gu, ion_bfieldz_gu =
         field1:get(ion_px_mm, ion_py_mm, ion_pz_mm)
	elseif ion_instance == 2 then
		ion_bfieldx_gu, ion_bfieldy_gu, ion_bfieldz_gu =
         field2:get(ion_px_mm, ion_py_mm, ion_pz_mm)
		 
  
	end
end


function segment.flym()

	recheader =  "ion#, endposx (mm), endposy (mm), endposz (mm), endvelx (mm/usec), endvely (mm/usec), endvelz (mm/usec)\n"
	recpath = "recordings\\results.csv"
	results_file = opencsvforwrite (results_file, recpath,recheader)
	recpath_pep1 = "recordings\\rec_pep1.csv"
	results_file_pep1 = opencsvforwrite (results_file_pep1, recpath_pep1,recheader)
	
	recpath_pep2 = "recordings\\rec_pep2.csv"
	results_file_pep2 = opencsvforwrite (results_file_pep2, recpath_pep2,recheader)
	
	run()
	results_file:close()
	results_file_pep1:close()
	results_file_pep2:close()
	all_results_file:close()
end

-- Called on every time-step.
function segment.other_actions()
  -- (Optional) Provide some visual effects here.
  -- Things like this can assist in understanding.

  -- magnitude of field
  local bm = sqrt(ion_bfieldx_mm^2 + ion_bfieldy_mm^2 + ion_bfieldz_mm^2)
   
  if bm > 300 then
    ion_color = 2  -- green
  else
    ion_color = 1  -- red
  end
  if bm == 0 then  -- outside of field
    mark()
  end
 -- print("pep1",pep1_end_mm,"dx",dx_mm,"lebtend",lebt_end_mm)
 
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

function segment.terminate()
  -- Record some metric for each particle splat.
  
  results_file:write(ion_number .. "," .. ion_px_mm ..
                                   "," .. ion_py_mm ..
                                   "," .. ion_pz_mm ..
                                   "," .. ion_vx_mm ..
                                   "," .. ion_vy_mm ..
                                   "," .. ion_vz_mm .."\n")
  results_file:flush()  -- immediately output to disk
  
 
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
     
  

  -- Save the results of the current run --
  all_results_file:write(emit_y0..","..norm_emit_y0..","..
                         emit_z0..","..norm_emit_z0..","..
                         emit_y1..","..norm_emit_y1..","..
                         emit_z1..","..norm_emit_z1..","..
                         emit_y2..","..norm_emit_y2..","..
                         emit_z2..","..norm_emit_z2..",".. 
                         -- v_rms_y1..","..v_stdev_y1..","..
                         -- v_rms_z1..","..v_stdev_z1..","..
                         v_rms_y0..","..v_rms_z0..","..
                         v_rms_y1..","..v_rms_z1.."\n")

end