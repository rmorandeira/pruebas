PROGRAM len_prog1;

USES crt,strings,graph;
CONST
    centro=500;
TYPE
    archivo=FILE OF CHAR;
    arbol=^nodo;
    nodo=RECORD
               dato:STRING;
               nodo_izq:arbol;
               nodo_medio:arbol;
               nodo_der:arbol;
    END;
{********************************************************************************************}
FUNCTION obtieneValor (cad:STRING):INTEGER;  {Obtiene el valor de un STRING y lo devuelve como INTEGER}
VAR
   aux:INTEGER;
BEGIN
     val(cad,aux,aux);
     obtieneValor:=aux;
END;
{********************************************************************************************}
PROCEDURE iniciaGraf;           {Inicio del modo grafico}
VAR
 grDriver: Integer;
 grMode: Integer;
 ErrCode: Integer;
BEGIN
 grDriver := Detect;
 InitGraph(grDriver, grMode,' ');
 ErrCode := GraphResult;
 SetTextStyle(DefaultFont, HorizDir, 1);
 IF ErrCode <> grOk THEN
   Writeln('Error inicializando graficos', GraphErrorMsg(ErrCode));
 ClearDevice;
END;
{********************************************************************************************}
FUNCTION tamArchivo (ruta:STRING):INTEGER;   {Devuelve el tama¤o del archivo}
VAR
   fich:archivo;
BEGIN
       Assign(fich,ParamStr(1));
       Reset(fich);
       tamArchivo:=FileSize(fich);
       Close(fich);
END;
{********************************************************************************************}
FUNCTION verArbol (a:arbol;x,y:INTEGER):BOOLEAN;       {pasamos un arbol, y la posicion de inicio de la rama}
BEGIN
     SetColor(15);
     IF (a<>NIL) THEN
     BEGIN
        IF (a^.dato='+') OR (a^.dato='-') THEN
           SetFillStyle(1,3) {relleno operadores}
        ELSE
           IF (a^.dato='E') OR (a^.dato='D') THEN
               SetFillStyle(1,1){relleno E y D}
           ELSE
               SetFillStyle(1,9); {relleno digitos}
        FillEllipse(x+4,y+3,15,15);
        OutTextXY(x-7,y,a^.dato);
        IF verArbol(a^.nodo_izq,x-50,y+50) THEN
             Line(x-6,y+14,x-35,y+43);   {Diagonal Izquierda}
        IF verArbol(a^.nodo_der,x+50,y+50) THEN
             Line(x+16,y+14,x+43,y+41);  {Diagonal Derecha}
        IF verArbol(a^.nodo_medio,x,y+50) THEN
             Line(x+4,y+18,x+4,y+38);  {Nodo Operador}
     END
     ELSE
        verArbol:=FALSE;        {Cuando es un digito no debe pintar diagonales}
END;
{********************************************************************************************}
PROCEDURE creaPosfija(a:arbol;VAR fich:archivo);    {Crea la notacion posfija en el archivo a partir del arbol}
VAR
   aux:INTEGER;
BEGIN
     IF (a<>NIL) THEN
     BEGIN
          IF (a^.dato='E') THEN
          BEGIN
               IF(a^.nodo_medio^.dato<>'D') THEN
               BEGIN
                    creaPosfija(a^.nodo_izq,fich);
                    creaPosfija(a^.nodo_der,fich);
{                    Write(fich,a^.nodo_medio^.dato);}
               END
               ELSE
                    creaPosfija(a^.nodo_medio,fich);
          END
          ELSE
          BEGIN
{               Write(fich,a^.nodo_medio^.dato)}
          END;
     END;
END;
{********************************************************************************************}
PROCEDURE creaFicheroSalida (ruta:STRING;a:arbol);  {Crea el archivo de salida,o lo sobreescribe}
VAR
   fich:archivo;
BEGIN
     Assign(fich,ruta);
     Rewrite(fich);
     creaPosfija(a,fich);
     Close(fich);
END;
{********************************************************************************************}
FUNCTION existeFichero (ruta:STRING):BOOLEAN;           {Devuelve un booleano con la existencia de un fichero}
VAR
   a:archivo;
   cadena:STRING;
BEGIN
     {$I-}
     Assign(a,ruta);
     Reset(a);
     {$I+}
     IF IORESULT<>0 THEN
        existeFichero:=FALSE
     ELSE
        existeFichero:=TRUE;
END;
{********************************************************************************************}
PROCEDURE dibujaFlecha (x,y:INTEGER);         {Dibuja la flecha de error}
BEGIN
     SetColor(12);
     x:=x+5;
     line(x,y,x,y+10);
     line(x,y,x-3,y+3);
     line(x,y,x+3,y+3);
     SetColor(4);
     OutTextXY(x-15,y+15,'ERROR');
END;
{********************************************************************************************}
PROCEDURE mostrarLeyenda;                       {Muestra una peque¤a leyenda en la visualizacion}
BEGIN
     Rectangle(350,20,540,130);
     OutTextXY(355,25,'LEYENDA');
     SetFillStyle(1,1);
     FillEllipse(365,50,10,10);
     OutTextXY(385,50,'Expresion y Digitos');
     SetFillStyle(1,3);
     FillEllipse(365,80,10,10);
     OutTextXY(385,80,'Operadores');
     SetFillStyle(1,9);
     FillEllipse(365,110,10,10);
     OutTextXY(385,110,'Digitos');

END;
{********************************************************************************************}
FUNCTION leeToken (pos:INTEGER;sentido:BOOLEAN):STRING ;     {Lee un token del archivo en la posicion indicada}
VAR
   fich:archivo;
   token:CHAR;
   incremento:INTEGER;
BEGIN
     IF sentido THEN            {sentido=TRUE incremento decreciente}
        incremento:=-1
     ELSE
        incremento:=0;          {sentido=FALSE incremento 0}
     Assign(fich,ParamStr(1));
     Reset(fich);
     Seek(fich,pos+incremento);
     Read(fich,token);
     Close(fich);
     leeToken:=token;
END;
{********************************************************************************************}
PROCEDURE mostrarErrorCadena(i:INTEGER);           {Muestra la posicion del error en la cadena}
VAR
   j:INTEGER;
   cadena:STRING;
BEGIN
     cadena:='';
     FOR j:=0 TO tamArchivo(ParamStr(1))-1 DO
     BEGIN
          cadena:=cadena + leeToken(j,FALSE);
     END;
     OutTextXY(100,50,cadena);
     dibujaFlecha(100+(i*7),65);        {Habria que ajustar mejor la flecha}
END;
{********************************************************************************************}
PROCEDURE muestraAyuda;                 {Muestra una peque¤a ayuda}
BEGIN
     OutTextXY(50,160,'La sintaxis correcta es P1A.EXE fichero_entrada fichero_salida');
END;
{********************************************************************************************}
PROCEDURE mostrarError(tipo,pos:INTEGER); {Manejador de errores}
BEGIN
     CASE tipo OF
          1:
          BEGIN
            OutTextXY(50,100,'Error de digito');
            mostrarErrorCadena(pos);
          END;
          2:
          BEGIN
            OutTextXY(50,100,'Error de operador');
            mostrarErrorCadena(pos);
          END;
          3:
          BEGIN
            OutTextXY(50,150,'Error,no existe el fichero de entrada');
            muestraAyuda;
          END;
          4:
          BEGIN
            OutTextXY(50,150,'Error,no existe el fichero de salida');
            muestraAyuda;
          END;
          5:
          BEGIN
            OutTextXY(50,100,'Error de parentesis');
            mostrarErrorCadena(pos);
          END;
     END;
     ReadLn;
END;
{********************************************************************************************}
FUNCTION esParentesis(VAR pos:INTEGER):BOOLEAN;
VAR
   token:STRING;
BEGIN
     token:=leeToken(pos,TRUE);
     IF (token='(') OR (token=')') THEN
     BEGIN
       pos:=pos-1;
       esParentesis:=TRUE;
     END
     ELSE
          esParentesis:=FALSE;
END;
{********************************************************************************************}
FUNCTION esParentesis_A(VAR pos:INTEGER):BOOLEAN;
VAR
   token:STRING;
BEGIN
     token:=leeToken(pos,TRUE);
     IF (token=')') THEN
     BEGIN
        pos:=pos-1;
        esParentesis_A:=TRUE;
     END
     ELSE
        esParentesis_A:=FALSE;
END;
{********************************************************************************************}
FUNCTION esParentesis_C(VAR pos:INTEGER):BOOLEAN;
VAR
   token:STRING;
BEGIN
     token:=leeToken(pos,TRUE);
     IF (token='(') THEN
     BEGIN
        pos:=pos-1;
        esParentesis_C:=TRUE;
     END
     ELSE
        esParentesis_C:=FALSE;
     pos:=pos-1;
END;
{********************************************************************************************}
FUNCTION esOperador(VAR pos:INTEGER;VAR a:arbol):BOOLEAN; {Funcion que nos devuelve si es operador, y lo mete en el arbol}
VAR
   token:STRING;
BEGIN
     new(a);
     token:=leeToken(pos,TRUE);
     IF (token<>'+') AND (token<>'-') THEN
     BEGIN
         mostrarError(2,pos);
         esOperador:=FALSE
     END
     ELSE
     BEGIN
        a^.dato:=token;
        a^.nodo_izq:=NIL;
        a^.nodo_medio:=NIL;
        a^.nodo_der:=NIL;
        esOperador:=TRUE;
     END;
     pos:=pos-1;
END;
{********************************************************************************************}
FUNCTION esDigito(VAR pos:INTEGER;VAR a:arbol):BOOLEAN; {Funcion que nos devuelve si es digito, y lo mete en el arbol}
VAR
   d:arbol;
   aux,token:STRING;
BEGIN
     new(a);
     token:='';
     aux:=leeToken(pos,TRUE);
     WHILE (aux<='9') AND (aux>='0') AND (pos>1) DO
     BEGIN
          token:=aux + token;
          pos:=pos-1;
          aux:=leeToken(pos,TRUE);

     END;
     IF pos=1 THEN
        token:=aux + token;
     IF (obtieneValor(token)<=999) AND (obtieneValor(token)>=0) THEN
     BEGIN
        new(d);
        d^.dato:=token;
        d^.nodo_izq:=NIL;
        d^.nodo_medio:=NIL;
        d^.nodo_der:=NIL;
        a^.dato:='D';
        a^.nodo_izq:=NIL;
        a^.nodo_medio:=d;
        a^.nodo_der:=NIL;
        esDigito:=TRUE;
     END
     ELSE
     BEGIN
        mostrarError(1,pos);
        esDigito:=FALSE;
     END;
END;
{********************************************************************************************}
FUNCTION esExpresion(pos:INTEGER;VAR a:arbol):BOOLEAN; {Funcion que evalua las reglas de produccion}
VAR
   correcto:BOOLEAN;
BEGIN
     new(a);
     a^.dato:='E';
     IF esParentesis_A(pos) THEN
     BEGIN
        esExpresion:=esExpresion(pos,a^.nodo_izq);
        IF NOT esParentesis_C(pos) THEN
           mostrarError(5,pos);
     END
     ELSE
     BEGIN
     correcto:=esDigito(pos,a^.nodo_der);
     IF (pos<>1) AND (correcto) THEN
     BEGIN
          correcto:=esOperador(pos,a^.nodo_medio);
{          IF correcto THEN}
             esExpresion:=esExpresion(pos,a^.nodo_izq)
     END
     ELSE
         esExpresion:=correcto;
     END;
END;
{********************************************************************************************}
FUNCTION sobreEscribir:BOOLEAN;  {Nos pregunta si deseamos sobreescribir un archivo}
VAR
   tecla:CHAR;
BEGIN
     OutTextXY(50,150,'El fichero ' + ParamStr(2) + ' ya existe, desea sobreescribirlo? (S/N)');
     ReadLn(tecla);
     IF (tecla='S') OR (tecla='s') THEN
        sobreEscribir:=TRUE
     ELSE
        sobreEscribir:=FALSE;
END;
{********************************************************************************************}
{PROGRAMA PRINCIPAL}
VAR
   a:arbol;
   cadena:STRING;
   error:INTEGER;
   fich:archivo;
   continua:BOOLEAN;
BEGIN
     iniciaGraf;
     ClearDevice;
     Outtext(ParamStr(1));
     IF (ParamStr(1)='') OR NOT existeFichero (ParamStr(1)) THEN
        mostrarError(3,-1)
     ELSE
     BEGIN
          new(a);
{          IF ParamStr(2)='' THEN
             mostrarError(4,-1)
          ELSE}
          BEGIN
               IF esExpresion(tamArchivo(ParamStr(1)),a)=TRUE THEN
               BEGIN
                    verArbol(a,centro,150);
                    mostrarLeyenda;
                    ReadLn;
{                    IF existeFichero(ParamStr(2)) THEN
                    BEGIN
                       IF sobreEscribir THEN
                          creaFicheroSalida(ParamStr(2),a);
                    END
                    ELSE}
                          creaFicheroSalida(ParamStr(2),a);
               END;
          END;
          Dispose(a);
     END;
     CloseGraph;
END.
