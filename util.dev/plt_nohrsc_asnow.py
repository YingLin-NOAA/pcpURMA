# Plots precipitation analysis
#
# from pcpverif/util.dev/plot/snow/plt_nohrsc_asnow.py.  
import matplotlib
matplotlib.use('Agg')   #Necessary to generate figs when not running an Xserver (e.g. via PBS)
from ncepy import corners_res, gem_color_list, ndate
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
import pygrib
import sys 

infile=sys.argv[1]
infile_w_o_grb2=infile.replace('.grb2','')
grbfin = pygrib.open(infile)
asnow = grbfin.select(name='Total snowfall')[0]
# Convert ASNOW from meter to inches:
vals = asnow.values*39.3701
grbfin.close()

# Get the lats and lons
lats, lons = asnow.latlons()

# Set contour levels for precip    
clevs = [ 0.0, 0.1, 1, 2, 4, 6, 8, 12, 18, 24, 30, 36 ]
 
#Use gempak color table for precipitation
gemlist=gem_color_list()
# Use gempak fline color levels from pcp verif page
pcplist=[31,28,25,21,23,19,20,11,12,2,14,30,1]

#Extract these colors to a new list for plotting
pcolors=[gemlist[i] for i in pcplist]

# Set up the colormap and normalize it so things look nice
mycmap=matplotlib.colors.ListedColormap(pcolors)
norm = matplotlib.colors.BoundaryNorm(clevs, mycmap.N)

fig = plt.figure(figsize=(8,8))
m = Basemap(llcrnrlon=-119,llcrnrlat=22,urcrnrlon=-64,urcrnrlat=49,
         resolution='l',projection='lcc',lat_1=33,lat_2=45,lon_0=-95)
m.drawcoastlines(linewidth=0.5)
m.drawcountries(linewidth=0.5)
m.drawstates(linewidth=0.5)

#cf = m.contourf(lons,lats,vals,clevs,latlon=True,colors=pcolors,extend='max')
cf = m.contourf(lons,lats,vals,clevs,cmap=mycmap,norm=norm,latlon=True,extend='max')
cf.set_clim(0,36) 
plt.title(infile_w_o_grb2)
# add colorbar.
cbar = m.colorbar(cf,location='bottom',pad="5%",ticks=clevs,format='%.1f')    
cbar.ax.tick_params(labelsize=8.5)    
cbar.set_label('inches')

plt.savefig(infile_w_o_grb2+'.png',bbox_inches='tight')

