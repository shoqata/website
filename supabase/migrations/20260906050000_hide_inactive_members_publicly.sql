-- Entfernte Mitglieder verschwinden auch aus der oeffentlichen Ansicht.
--
-- "Entfernen" setzt membershipStatus auf INACTIVE, statt die Zeile zu loeschen:
-- an ihr haengen Zahlungen, Journalbuchungen und Vorstandsmandate. Die
-- Startseite und die Ueber-uns-Seite lesen public_members, also muss der Filter
-- dort sitzen -- sonst zaehlt die Mitgliederzahl auf der Startseite weiter mit
-- und der Name laeuft in der Marquee.
--
-- PENDING bleibt sichtbar wie bisher; nur ausdruecklich entfernte fallen raus.
CREATE OR REPLACE VIEW public.public_members AS
  SELECT id,
         "displayName",
         "photoFileName",
         city,
         country,
         "membershipStatus",
         "livesInKoretin"
    FROM public.users
   WHERE "membershipStatus" IS DISTINCT FROM 'INACTIVE';
