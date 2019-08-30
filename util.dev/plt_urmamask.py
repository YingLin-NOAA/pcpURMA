# Plots precipitation analysis
#
# From Jacob Carley's NAMRR 'plot hourly QPF' code
import matplotlib
matplotlib.use('Agg')   #Necessary to generate figs when not running an Xserver (e.g. via PBS)
from ncepy import corners_res, gem_color_list, ndate
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from matplotlib import colors as c
import numpy as np
import pygrib
import sys 

infile=sys.argv[1]
tmpname=infile.replace('.grb2','')

grbfin = pygrib.open(infile)
mask = grbfin.read(1)[0]
vals = mask.values
grbfin.close()

# Get the lats and lons
lats, lons = mask.latlons()
  
#Get the date/time and forecast hour
frange_end=mask['stepRange'] # Forecast hour  #since this is an accumulation we don't have forecast hour but a forecast range
dummy1,sep,dummy2=frange_end.partition('-')  #for 4-5 hour accumulation we want the 5 since that's the length of the forecast
                                               # we already know this is 1hr qpf anyway and this grib file has just a single field.   
acchr=dummy2
print 'acchr =', acchr

#clevs = [0,1,150,152,153,154,155,156,157,158,159,160,161,162,170]
clevs = [98,99,150,152,153,154,155,156,157,158,159,160,161,162,170]
#Use gempak color table for precipitation
gemlist=gem_color_list()
#pcplist=[0,31,23,22,21,20,19,10,17,16,15,14,29,28,25,24]
masklist=[11,31,23,15,21,20,19,10,17,16,22,14,29,28,25,24]
#Extract these colors to a new list for plotting
pcolors=[gemlist[i] for i in masklist]
# Use gempak fline color levels from pcp verif page
#cm = c.ListedColormap(['green','red','magenta','blue'])
cm = c.ListedColormap(pcolors)
cm.set_under(alpha = 0.0)
norm = c.BoundaryNorm(clevs, cm.N)
fig = plt.figure(figsize=(8,8))
#m = Basemap(llcrnrlon=-126,llcrnrlat=16,urcrnrlon=-52,urcrnrlat=54,
#         resolution='l',projection='lcc',lat_1=33,lat_2=45,lon_0=-95)

# plot in plain lat/lon projection:
llcrnrlon=-139
llcrnrlat=18
urcrnrlon=-58
urcrnrlat=58
m = Basemap(projection='cyl',llcrnrlon=llcrnrlon,llcrnrlat=llcrnrlat,
                             urcrnrlon=urcrnrlon,urcrnrlat=urcrnrlat,
                             resolution='l')
m.drawcoastlines(linewidth=0.5)
m.drawcountries(linewidth=0.5)
m.drawstates(linewidth=0.5)
cf = m.pcolormesh(lons,lats,vals,cmap=cm,vmin=0,vmax=162,norm=norm,latlon=True)
cf.set_clim(0,162) 
plt.title(tmpname)
# add colorbar.
cbar = m.colorbar(cf,location='bottom',pad="5%",ticks=clevs)    
cbar.ax.tick_params(labelsize=8.5)    
cbar.set_label('98-CMORPH, 99-MRMS; RFC IDs: 150,152,...162')

plt.savefig(tmpname+'.png',bbox_inches='tight')
