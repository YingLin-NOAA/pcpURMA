# Plots precipitation analysis
#
# From Jacob Carley's NAMRR 'plot hourly QPF' code
import matplotlib
matplotlib.use('Agg')   #Necessary to generate figs when not running an Xserver (e.g. via PBS)
from ncepy import corners_res, gem_color_list, ndate
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
import pygrib
import sys 

infile=sys.argv[1]
domain=sys.argv[2]


tmpname=infile.replace('.grb2','')

grbfin = pygrib.open(infile)
#
if domain == 'global':
  llcrnrlon=-0
  llcrnrlat=-90
  urcrnrlon=360
  urcrnrlat=90
elif domain == 'conus':
  llcrnrlon=-139
  llcrnrlat=18
  urcrnrlon=-58
  urcrnrlat=58
elif domain == 'ak':
  llcrnrlon=-179
  llcrnrlat=45
  urcrnrlon=-120
  urcrnrlat=77
elif domain == 'pr':
  llcrnrlon=-68.5
  llcrnrlat=16.5
  urcrnrlon=-63.7
  urcrnrlat=20

#pcp = grbfin.select(name='Total Precipitation')[0]
# want this to work with MRMS file on wexp grid, whose parm has not been
# renamed 'Total Precipitation'. 
pcp = grbfin.read(1)[0]
vals = pcp.values
grbfin.close()

# Get the lats and lons
lats, lons = pcp.latlons()

# Set contour levels for precip    
clevs = [0,0.1,2,5,10,15,20,25,35,50,75,100,125,150,175]
 
#Use gempak color table for precipitation
gemlist=gem_color_list()
# Use gempak fline color levels from pcp verif page
pcplist=[31,23,22,21,20,19,10,17,16,15,14,29,28,24,25]
#Extract these colors to a new list for plotting
pcolors=[gemlist[i] for i in pcplist]

# Set up the colormap and normalize it so things look nice
mycmap=matplotlib.colors.ListedColormap(pcolors)
norm = matplotlib.colors.BoundaryNorm(clevs, mycmap.N)

fig = plt.figure(figsize=(8,8))
m = Basemap(projection='cyl',llcrnrlon=llcrnrlon,llcrnrlat=llcrnrlat,
                             urcrnrlon=urcrnrlon,urcrnrlat=urcrnrlat,
                             resolution='l')
m.drawcoastlines(linewidth=0.5)
m.drawcountries(linewidth=0.5)
m.drawstates(linewidth=0.5)

#cf = m.contourf(lons,lats,vals,clevs,latlon=True,colors=pcolors,extend='max')
cf = m.contourf(lons,lats,vals,clevs,cmap=mycmap,norm=norm,latlon=True,extend='max')
cf.set_clim(0,175) 
plt.title(tmpname)
# add colorbar.
cbar = m.colorbar(cf,location='bottom',pad="5%",ticks=clevs,format='%.1f')    
cbar.ax.tick_params(labelsize=8.5)    
cbar.set_label('mm')

plt.savefig(tmpname+'.png',bbox_inches='tight')

