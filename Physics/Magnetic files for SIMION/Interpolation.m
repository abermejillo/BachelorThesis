[X Y Z Bx By Bz] = csvimport ('C:\Users\Alvaro\Documents\Simion Mag Files\Ansys_Bfield_notapes_-8A_18mm.csv', 'columns', {'X','Y','Z','Bx','By','Bz'});
% In ansys the longitudinal axis is X (also in simion)
[Xm Ym Zm] = csvimport ('simion_rectangular_mesh261_1mm_18d.csv', 'columns', {'Xm', 'Ym', 'Zm'});
% In the experimental measurements the longitudinal axis is Y and the
% magnetic field is aligned correctly (B_y along Y)
X = X*1000; Y = Y*1000; Z = Z*1000;
F = scatteredInterpolant (X, Y, Z, Bx);F.Method = 'natural';
G = scatteredInterpolant (X, Y, Z, By);G.Method = 'natural';
H = scatteredInterpolant (X, Y, Z, Bz);H.Method = 'natural';
%Ya tenemos de esta forma una función que me da el valor del campo en
%cualquier punto del espacio. Ahora hay que encontrar el grid en el cual
%queremos encontrar el campo. Luego hay que generar el fichero cvs con las
%coordenadas XYZBxByBz. 
Xm = Xm -30;
Bxi = 10000*F(Xm,Ym,Zm); % The magnetic fiel in SIMION is in Gauss
Byi = 10000*G(Xm,Ym,Zm);
Bzi = 10000*H(Xm,Ym,Zm);
Xm = Xm +30;
M = [Xm Ym Zm Bxi Byi Bzi];
Mx = [Xm Ym Zm Bxi];
My = [Xm Ym Zm Byi];
Mz = [Xm Ym Zm Bzi];
csvwrite('SNIF-8A_notapes.csv',M);
%csvwrite('SNIF-8A_14mm_long_1mmx.csv',Mx);
%csvwrite('SNIF-8A_14mm_long_1mmy.csv',My);
%csvwrite('SNIF-8A_14mm_long_1mmz.csv',Mz);
