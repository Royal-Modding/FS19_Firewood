# FS19_Firewood

Firewood mod for Farming Simulator 19

## Funzionamento

La mod permette di trasformare piccoli pezzi di legna in legna da ardere inserendoli in pallet vendibili alla segheria
per i più pigri possibilità di trasformare interi alberi e/o tronchi di grosse dimensioni in legna da ardere all'istante.

## Requisiti

- raycast su player separato da raycast standard di gioco, oggetto di tipo shape ed abbia splittype.
- Acquisto del pallet vuoto
  - in shop
    - spawn diretto alla posizione del player (costo più alto)

- per poter essere collocato nel pallet lo split shape deve avere i seguenti requisiti
  - sss

- il workaround per pezzi grandi prevede una penalizzazione
  - sss

- vendita del pallet alla segheria

- tipo di pallet effettivo da definire

## Cose da fare


- [ ] ingrandire il trigger del sellPoint piccolo (scale ok ?)
- [x] punto di spawn quando si visita il punto vendita VisualSellPoint (linkNode in xml)
- [x] Ricorda di provare gli spacca legna
- [x] Mettere il foliage bending al pallet
- [ ] per far funzionare il bending nei pallet va estesa la classe foliageBending perché deve essere activated e non lo è.
      vedi parametro xml aggiunti alwaysActive="true"
      
- [x] Controllare  `Error: Running LUA method 'update'. FS19_Firewood/FirewoodBuyerPlaceable.lua:198: attempt to index field 'weatherInfo' (a nil value)`

