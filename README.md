# callVizieRMatlab
 Query gaia Dr1,URAT1 and PPMXL with VizieR
 see http://cdsarc.u-strasbg.fr/doc/asu-summary.htx
 and http://cds.u-strasbg.fr/doc/asu.html
 for details , now it's a easy mode
Only support for a box region !
Fisrt version 2017/3/20 by vanckyli[at]gmail.com
## Useage:
```matlab
t=queryVizieR(10.684708,41.232,2,4);
t=t.get_urat1();
disp(t.fields)
summary(t.data);
```