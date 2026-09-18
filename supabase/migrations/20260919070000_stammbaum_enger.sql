-- Die verantwortliche Person einer Nachbarschaft sah die Verwandtschaft des
-- ganzen Vereins.
--
-- Bei den Mitgliedsdaten selbst ist sie auf ihre Nachbarschaften begrenzt.
-- Hier war sie es nicht -- ueber die Verwandtschaft waere also ableitbar
-- gewesen, wer anderswo zu wem gehoert, obwohl sie diese Personen gar nicht
-- sehen darf. Aufgefallen bei einer Probe als angemeldeter Benutzer; die
-- vorherige Probe lief als Datenbankrolle und ging an der Regel vorbei.
--
-- Die Verwaltung sieht weiterhin alles.
DROP POLICY IF EXISTS family_links_lesen ON public.family_links;
CREATE POLICY family_links_lesen ON public.family_links
  FOR SELECT TO authenticated
  USING (
    "tenantId" = public.current_tenant()
    AND (
      public.is_member_manager()
      OR (
        public.is_neighborhood_steward()
        AND EXISTS (
          SELECT 1 FROM public.users u
           WHERE u.id IN (family_links.von, family_links.nach)
             AND u."neighborhoodId" IN (SELECT public.my_neighborhoods())
        )
      )
    )
  );
