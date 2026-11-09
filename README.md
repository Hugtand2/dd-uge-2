# dd-uge-2
Undulaternes DDU projekt 2

Spilmæssigt:
Spillet handler om at hjæpe folk med deres skat. 
Det ligner strukturelt "Papers, Please" spillet.
Folk giver deres TaxForms, og du skal tjekke hvor meget de er off, og skrive det ned som svar, og sende dem vidre.
Du får score for at være spot on på dine gæt, ift. hvor meget skat de skal skylder/skyldes.
Eksempel: -En person skal betale indkomstskat af sit normale arbejde -
-Han giver en A-SKAT TaxForm. Du kan regne hvad han skylder, og fylde de tomme labels ud.-

Kodemæssigt:
Filstruktur er meget vigtigt når vi laver ny kode
ALT testing, SKAL ske i !Debug
Classes er der hvor vi gemmer kode for objekter der skal instantieres flere gange, ting som TaxForm eller Customer
Rescources er lydfiler, sprites, billeder osv.
Scenes&Scripts gemmer godot scener, samt kode til ting som bell, der kun laves én gang.
Setup er til kode, der skal køres så snart spillet starter. Lyd findes for eksempelvis i setup.

Kodestil:
Scener er snake_case
Scripts er snake_case
Classes er camelCase
Rescources som lyd, billeder og sprites navngives valgfrit


