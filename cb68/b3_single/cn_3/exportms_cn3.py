import os

##############################################################
'''
  Exporting Pipeline calibrated CASA MS to FITS files
'''
##### Define variables #######################################

# The CASA MS to export
ms_path_7m = '../../calibrated/7m/'
all_7m_ms = [               
               os.path.join(ms_path_7m, 'uid___A002_X10b6f7c_X1fad3.ms'),
               os.path.join(ms_path_7m, 'uid___A002_X10b6f7c_X1ff3f.ms') ]

ms_path_12m = '../../calibrated/12m/'
all_12m_ms = [ os.path.join(ms_path_12m, 'uid___A002_X1020da2_X83be.ms') ]

# The spectral windows to export
spwID_7m = ['33']
spwID_12m = ['41']

# rest frequency (central frequency in spw setup)
molecule = ['cn_3']

restfreq = ['113.5089074GHz']


# The head of the output FITS file name
head_7m = '7m'
head_12m = '12m'

# the certain high-emission channels for test
mode = 'velocity'
outframe = 'LSRK'

# velocity gridding in the output
vel_start  = '81.9277km/s'
vel_width  = '-0.323km/s'
vel_nchan  = 476



##### flow control ##############################################
thesteps = []
step_title = {
              0: 'Output listobs files',
              1: 'Split individual target source fields in to MS files',
              2: 'Continuum subtraction',
			        3: 'Export the observations of each visibility on each field to FITS'
             }

try:
  print ('List of steps to be executed ...', mysteps)
  thesteps = mysteps
except:
  print ('global variable mysteps not set.')

if (thesteps==[]):
  thesteps = range(0,len(step_title))
  print ('Executing all steps: ', thesteps)


##### output listobs file #####################################
mystep = 0
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  for vis in all_7m_ms:
    listfile = vis + '.listobs'
    os.system('rm -rf ' + listfile)
    listobs(vis = vis, listfile = listfile)

  for vis in all_12m_ms:
    listfile = vis + '.listobs'
    os.system('rm -rf ' + listfile)
    listobs(vis = vis, listfile = listfile)
##############################################################



##### Split individual target source fields in to MS files ###
mystep = 1
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  print('########################################\n')
  print('Exporting 7m single field: ')

  for visID in range(len(all_7m_ms)):
    vis = all_7m_ms[visID]

    for spw_num in range(len(spwID_7m)):

      splitms = head_7m + '_vis' + str(visID) + '_' + molecule[spw_num] + '.ms'
      
      os.system('rm -rf ' + splitms )

      mstransform(
                  vis = vis, 
                  outputvis  = splitms,
					        spw = spwID_7m[spw_num],
                  restfreq = restfreq[spw_num],
                  field = '2',
                  regridms = True, 
					        mode  = mode,
					        outframe = outframe,
				          nchan = vel_nchan,
					        start = vel_start,
					        width = vel_width
                )
      
  ### 12m
  print('########################################\n')
  print('Exporting 12m single field: ')

  for visID in range(len(all_12m_ms)):
    vis = all_12m_ms[visID]

    for spw_num in range(len(spwID_12m)):

      splitms = head_12m + '_vis' + str(visID) + '_' + molecule[spw_num] + '.ms'
      
      os.system('rm -rf ' + splitms )

      # split data
      mstransform(
                  vis = vis, 
                  outputvis  = splitms,
					        spw = spwID_12m[spw_num],
                  restfreq = restfreq[spw_num],
                  field = '2',
                  regridms = True,
					        mode  = mode,
					        outframe = outframe,
					        nchan = vel_nchan,
					        start = vel_start,
					        width = vel_width
                )

#################################################################################

##### Continuum subtraction #####################################################
mystep = 2
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  for visID in range(len(all_7m_ms)):	
    for spw_num in range(len(spwID_7m)):

      split_ms = head_7m + '_vis' + str(visID) + '_' + molecule[spw_num] + '.ms'
        
      uvcontsub(
                vis = split_ms,
				        fitspw = '0:10~60;400~470',
				        want_cont = False
				      )
      os.system('rm -rf ' + split_ms)

        
  ### 12m
  for visID in range(len(all_12m_ms)):	
    for spw_num in range(len(spwID_12m)):

      split_ms = head_12m + '_vis' + str(visID) + '_' + molecule[spw_num] + '.ms'
          
      uvcontsub(
                vis = split_ms,
                fitspw = '0:10~60;400~470',
                want_cont = False
              )
      
      os.system('rm -rf ' + split_ms)


#################################################################################

##### Export the observations of each visibility on each field to FITS ##########
mystep = 3
if(mystep in thesteps):
  casalog.post('Step '+str(mystep)+' '+step_title[mystep],'INFO')
  print ('Step ', mystep, step_title[mystep])

  ### 7m
  for visID in range(len(all_7m_ms)):
    for spw_num in range(len(spwID_7m)):

      filenamehead = head_7m + '_vis' + str(visID) + '_' + molecule[spw_num]

      vis  = filenamehead + '.ms.contsub'
      fits = filenamehead + '.fits'

      os.system('rm -rf ' + fits )
      exportuvfits(
                    vis = vis, 
                    fitsfile = fits,
                    multisource = False, 
					          combinespw = False
                  )
      os.system('rm -rf ' + vis)
  
  ### 12m
  for visID in range(len(all_12m_ms)):
    for spw_num in range(len(spwID_12m)):

      filenamehead = head_12m + '_vis' + str(visID) + '_' + molecule[spw_num]

      vis  = filenamehead + '.ms.contsub'
      fits = filenamehead + '.fits'

      os.system('rm -rf ' + fits )
      exportuvfits(
                    vis = vis, 
                    fitsfile = fits,
                    multisource = False, 
					          combinespw = False
                  )
      
      os.system('rm -rf ' + vis)

###############################################################

