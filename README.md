etlrn
=====

script per funzionalita etl tirato su al volo


dopo il clone risolvere le dipendeze dalla cartella del progetto con > bumdle install
copiare config.yml.example in config.yml e aggiungere le proprie credenziali
i file a cui si fa riferimento nel config sono necessari, ma ovviamente non sotto versionamento

in ./db/migrate le procedure di creazione db d'appoggio
in ./etl.rb nell'ordine

- moduli di interfaccia altri db
- metodi per il caricamento
- classi sul db edda

per utilizzarlo da console > pry -r ./etl.rb
da console entrati situazione sottocampi > Discrict.situazione


PS Readme minimale si fa quel che si può a breve spero un upgrade

