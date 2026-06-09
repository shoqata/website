
import React, { createContext, useContext, useState, useEffect } from 'react';

type Language = 'en' | 'de' | 'sq';

interface Translations {
  [key: string]: {
    [key in Language]: string;
  };
}

const translations: Translations = {
  // --- COMMON ---
  'common.yes': { en: 'Yes', de: 'Ja', sq: 'Po' },
  'common.no': { en: 'No', de: 'Nein', sq: 'Jo' },
  'common.or': { en: 'OR', de: 'ODER', sq: 'OSE' },
  'common.back': { en: 'Back', de: 'Zurück', sq: 'Kthehu' },
  'common.next': { en: 'Next', de: 'Weiter', sq: 'Vazhdo' },
  'common.finish': { en: 'Finish', de: 'Abschließen', sq: 'Përfundo' },
  'common.loading': { en: 'Loading...', de: 'Laden...', sq: 'Duke ngarkuar...' },
  'common.error': { en: 'Error', de: 'Fehler', sq: 'Gabim' },
  'common.success': { en: 'Success', de: 'Erfolg', sq: 'Sukses' },
  'common.select': { en: 'Select...', de: 'Wählen...', sq: 'Zgjidh...' },
  'common.actions': { en: 'Actions', de: 'Aktionen', sq: 'Veprimet' },
  'common.search': { en: 'Search...', de: 'Suchen...', sq: 'Kërko...' },
  'common.cancel': { en: 'Cancel', de: 'Abbrechen', sq: 'Anulo' },
  'common.delete': { en: 'Delete', de: 'Löschen', sq: 'Fshij' },
  'common.edit': { en: 'Edit', de: 'Bearbeiten', sq: 'Ndrysho' },
  'common.save_changes': { en: 'Save Changes', de: 'Änderungen speichern', sq: 'Ruaj ndryshimet' },

  // --- NAVIGATION ---
  'nav.discover': { en: 'Discover', de: 'Entdecken', sq: 'Zbulo' },
  'nav.news.title': { en: 'Latest News', de: 'Aktuelle Nachrichten', sq: 'Të Rejat' },
  'nav.news.desc': { en: 'Updates from Koretin and the Diaspora.', de: 'Updates aus Koretin und der Diaspora.', sq: 'Lajme nga Koretini dhe Diaspora.' },
  'nav.events.title': { en: 'Events & Live', de: 'Events & Live', sq: 'Ngjarjet & Live' },
  'nav.events.desc': { en: 'Join community gatherings and projects.', de: 'Nimm an Treffen und Projekten teil.', sq: 'Bashkohuni në tubime dhe projekte.' },
  'nav.live': { en: 'Koretini Live', de: 'Koretini Live', sq: 'Koretini Live' },
  'nav.dashboard': { en: 'Dashboard', de: 'Dashboard', sq: 'Paneli' },
  'nav.admin': { en: 'Admin', de: 'Admin', sq: 'Admin' },
  'nav.logout': { en: 'Logout', de: 'Abmelden', sq: 'Dilni' },
  'nav.login': { en: 'Login', de: 'Anmelden', sq: 'Hyrja' },
  'nav.join': { en: 'Join', de: 'Beitreten', sq: 'Bashkohu' },
  'nav.adminAccess': { en: 'Admin Access', de: 'Admin Zugang', sq: 'Qasja Admin' },

  // --- HERO & LANDING ---
  'hero.badge': { en: 'Humanitarian Network', de: 'Humanitäres Netzwerk', sq: 'Rrjeti Humanitar' },
  'hero.title': { en: 'Together for our hometown.', de: 'Gemeinsam für unsere Heimat.', sq: 'Bashkë për vendlindjen tonë.' },
  'hero.subtitle': { en: 'Connecting the diaspora with local initiatives to build a better future.', de: 'Wir verbinden die Diaspora mit lokalen Initiativen für eine bessere Zukunft.', sq: 'Lidhja e diasporës me iniciativat lokale për të ndërtuar një të ardhme më të mirë.' },
  'hero.cta.register': { en: 'Join Now', de: 'Jetzt beitreten', sq: 'Regjistrohu Tani' },
  'hero.cta.login': { en: 'Login', de: 'Anmelden', sq: 'Kyçuni' },

  // --- SOCIAL AI ---
  'social.studio': { en: 'AI Studio', de: 'KI Studio', sq: 'Studio AI' },
  'social.config': { en: 'Configuration', de: 'Konfiguration', sq: 'Konfigurimi' },
  'social.topic.label': { en: 'Topic or Event', de: 'Thema oder Ereignis', sq: 'Tema apo Ngjarja' },
  'social.topic.placeholder': { en: 'e.g. Humanitarian dinner for the school...', de: 'z.B. Humanitäres Abendessen für die Schule...', sq: 'Psh: Darkë humanitare për shkollën...' },
  'social.tone.label': { en: 'Tone of Voice', de: 'Schreibstil', sq: 'Toni i shkrimit' },
  'social.lang.label': { en: 'Content Language', de: 'Inhaltssprache', sq: 'Gjuha e përmbajtjes' },
  'social.generate': { en: 'Generate Text with AI', de: 'Text mit KI generieren', sq: 'Gjenero tekstin me AI' },
  'social.analyze': { en: 'Analyze Photo & Write', de: 'Foto analysieren & schreiben', sq: 'Analizo foton & shkruaj' },
  'social.publish': { en: 'Publish Now', de: 'Jetzt veröffentlichen', sq: 'Publiko tani' },
  'social.schedule': { en: 'Schedule Post', de: 'Post planen', sq: 'Programo postimin' },
  'social.save_draft': { en: 'Save as Draft', de: 'Als Entwurf speichern', sq: 'Ruaj si draft' },
  'social.history': { en: 'Post History', de: 'Verlauf', sq: 'Historia e postimeve' },
  'social.autopost.label': { en: 'Auto-Post Automation', de: 'Auto-Post Automatisierung', sq: 'Automatizimi i Postimeve' },
  'social.autopost.desc': { en: 'When enabled, generated posts will be sent directly to social media upon clicking Publish.', de: 'Wenn aktiviert, werden generierte Posts beim Klicken auf Veröffentlichen direkt an Social Media gesendet.', sq: 'Kur aktivizohet, postimet do të dërgohen direkt në rrjete sociale me klikimin Publiko.' },
  'social.api.fb.title': { en: 'Facebook Graph API', de: 'Facebook Graph API', sq: 'Facebook Graph API' },
  'social.api.ig.title': { en: 'Instagram Business API', de: 'Instagram Business API', sq: 'Instagram Business API' },
  'social.api.token.label': { en: 'Access Token', de: 'Zugriffstoken', sq: 'Token i qasjes' },
  'social.api.id.label': { en: 'Entity ID', de: 'Entity ID', sq: 'ID e entitetit' },

  // --- AUTH (Login) ---
  'auth.has_account': { en: 'Already have an account?', de: 'Bereits ein Konto?', sq: 'Keni llogari?' },
  'auth.session_expired': { en: 'Your session has expired due to inactivity.', de: 'Deine Sitzung ist wegen Inaktivität abgelaufen.', sq: 'Seanca juaj ka skaduar për shkak të pasivitetit.' },
  'login.title': { en: 'Login', de: 'Anmelden', sq: 'Kyçuni' },
  'login.subtitle': { en: 'Access our solidarity community.', de: 'Zugang zu unserer Solidaritätsgemeinschaft.', sq: 'Hyni në komunitetin tonë të solidaritetit.' },
  'login.back': { en: 'Back', de: 'Zurück', sq: 'Kthehu' },
  'login.email.label': { en: 'Email Address', de: 'E-Mail Adresse', sq: 'Adresa e Email-it' },
  'login.email.placeholder': { en: 'name@example.com', de: 'name@beispiel.com', sq: 'emri@shembull.com' },
  'login.email.send': { en: 'Send Magic Link', de: 'Magic Link senden', sq: 'Dërgo Magic Link' },
  'login.password.label': { en: 'Password', de: 'Passwort', sq: 'Fjalëkalimi' },
  'login.password.forgot': { en: 'Forgot Password?', de: 'Passwort vergessen?', sq: 'Harruat fjalëkalimin?' },
  'login.submit': { en: 'Login', de: 'Einloggen', sq: 'Kyçuni' },
  'login.google': { en: 'Continue with Google', de: 'Weiter mit Google', sq: 'Vazhdo me Google' },
  'login.hero.title': { en: 'Welcome Back.', de: 'Willkommen zurück.', sq: 'Mirë se vini.' },
  'login.hero.desc': { en: 'Your contribution makes a difference. Log in to manage your membership.', de: 'Dein Beitrag macht den Unterschied. Melde dich an, um deine Mitgliedschaft zu verwalten.', sq: 'Kontributi juaj bën ndryshimin. Kyçuni për të menaxhuar anëtarësimin.' },
  'login.verifying': { en: 'Verifying...', de: 'Überprüfe...', sq: 'Duke verifikuar...' },
  'login.sent.title': { en: 'Magic Link Sent!', de: 'Link gesendet!', sq: 'Linku u dërgua!' },
  'login.sent.desc': { en: 'We sent a secure login link to:', de: 'Wir haben einen sicheren Link gesendet an:', sq: 'Ne dërguam një link të sigurt në:' },
  'login.sent.retry': { en: 'Send again', de: 'Erneut senden', sq: 'Dërgo sërish' },
  'login.method.password': { en: 'Password', de: 'Passwort', sq: 'Fjalëkalim' },
  'login.method.magic': { en: 'Magic Link', de: 'Magic Link', sq: 'Magic Link' },

  // --- REGISTRATION WIZARD ---
  'wizard.title': { en: 'Join Us', de: 'Mach mit', sq: 'Bashkohu me ne' },
  'wizard.step.1': { en: 'Account', de: 'Konto', sq: 'Llogaria' },
  'wizard.step.2': { en: 'Personal', de: 'Persönlich', sq: 'Personale' },
  'wizard.step.3': { en: 'Location', de: 'Standort', sq: 'Vendndodhja' },
  'wizard.step.4': { en: 'Verify', de: 'Prüfung', sq: 'Verifikimi' },
  'wizard.next': { en: 'Continue', de: 'Weiter', sq: 'Vazhdo' },
  'wizard.prev': { en: 'Back', de: 'Zurück', sq: 'Mbrapa' },
  'wizard.finish': { en: 'Finish', de: 'Abschließen', sq: 'Përfundo' },
  'wizard.success.title': { en: 'Check your email!', de: 'Prüfe deine E-Mails!', sq: 'Kontrolloni email-in!' },
  'wizard.success.desc': { en: 'We have sent a verification link.', de: 'Wir haben einen Bestätigungslink gesendet.', sq: 'Ne kemi dërguar një email verifikimi.' },

  // --- PROFILE SETUP & EDIT ---
  'setup.name.label': { en: 'Full Name', de: 'Vollständiger Name', sq: 'Emri i plotë' },
  'setup.phone.label': { en: 'Phone Number', de: 'Telefonnummer', sq: 'Numri i telefonit' },
  'profile.edit': { en: 'Edit Profile', de: 'Profil bearbeiten', sq: 'Ndrysho Profilin' },
  'profile.identity': { en: 'Identity', de: 'Identität', sq: 'Identiteti' },
  'profile.contact': { en: 'Contact', de: 'Kontakt', sq: 'Kontakt' },
  'profile.address': { en: 'Address', de: 'Adresse', sq: 'Adresa' },
  'profile.invoice_method': { en: 'Invoice Delivery', de: 'Rechnungsversand', sq: 'Mënyra e Faturimit' },

  // --- DASHBOARD ---
  'dash.welcome': { en: 'Welcome', de: 'Willkommen', sq: 'Mirë se vini' },
  'dash.subtitle': { en: 'Your membership overview', de: 'Deine Mitgliedschaftsübersicht', sq: 'Pasqyra e anëtarësimit tuaj' },
  'dash.intro': { en: 'Here is your overview of your contribution and community in', de: 'Hier ist deine Übersicht über deinen Beitrag und die Gemeinschaft in', sq: 'Këtu keni pasqyrën e kontributit tuaj dhe komunitetit në' },
  'dash.status.title': { en: 'Your Status', de: 'Dein Status', sq: 'Statusi Juaj' },
  'dash.status.active_paid': { en: 'Active / Paid', de: 'Aktiv / Bezahlt', sq: 'Aktiv / Paguar' },
  'dash.status.pending': { en: 'Pending', de: 'Ausstehend', sq: 'Në pritje' },
  
  // Invoice Card
  'dash.payment.title': { en: 'Membership Fee', de: 'Mitgliedsbeitrag', sq: 'Kuota e Anëtarësisë' },
  'dash.payment.qr': { en: 'Generate QR Bill', de: 'QR-Rechnung erstellen', sq: 'Gjenero Faturën QR' },
  'dash.invoice.open': { en: 'Open', de: 'Offen', sq: 'E Hapur' },
  'dash.invoice.amount': { en: 'Amount to pay', de: 'Betrag zu zahlen', sq: 'Shuma për pagesë' },
  'dash.invoice.due': { en: 'Due date', de: 'Fällig am', sq: 'Afati' },
  
  // Paid State
  'dash.invoice.all_paid_title': { en: 'Everything paid!', de: 'Alles bezahlt!', sq: 'Gjithçka e paguar!' },
  'dash.invoice.all_paid_desc': { en: 'Thank you for your contribution for year', de: 'Danke für deinen Beitrag für das Jahr', sq: 'Faleminderit për kontributit tuaj për vitin' },
  'dash.invoice.membership': { en: 'Membership', de: 'Mitgliedschaft', sq: 'Anëtarësia' },
  
  // Waiting State
  'dash.invoice.waiting_title': { en: 'Membership', de: 'Mitgliedschaft', sq: 'Anëtarësia' },
  'dash.invoice.waiting_desc': { en: 'Invoice for {year} has not been issued yet. You will be notified when ready.', de: 'Die Rechnung für {year} wurde noch nicht erstellt. Du wirst benachrichtigt.', sq: 'Fatura për vitin {year} ende nuk është lëshuar. Do të njoftoheni sapo të jetë gati.' },
  'dash.invoice.waiting_badge': { en: 'Pending issuance', de: 'Noch nicht verrechnet', sq: 'Në pritje të lëshimit' },

  'dash.history': { en: 'Payment History', de: 'Zahlungshistorie', sq: 'Historiku i Pagesave' },
  'dash.bank_details': { en: 'Bank Details', de: 'Bankverbindung', sq: 'Të Dhënat Bankare' },
  'dash.neighborhood.title': { en: 'My Neighborhood', de: 'Mein Quartier', sq: 'Lagja Ime' },
  'dash.qr.title': { en: 'Swiss QR Bill', de: 'Schweizer QR-Rechnung', sq: 'Fatura QR Zvicerane' },
  
  // Neighbors Section
  'dash.neighbors.title': { en: 'Your Neighbors', de: 'Deine Nachbarn', sq: 'Fqinjët Tuaj' },
  'dash.neighbors.subtitle': { en: 'Members of', de: 'Mitglieder von', sq: 'Anëtarët e' },
  'dash.neighbors.families': { en: 'Families', de: 'Familien', sq: 'Familjet' },
  'dash.neighbors.family_prefix': { en: 'Family', de: 'Familie', sq: 'Familja' },
  'dash.neighbors.individuals': { en: 'Individuals', de: 'Einzelpersonen', sq: 'Individët' },
  'dash.neighbors.first': { en: 'You are the first member here!', de: 'Du bist das erste Mitglied hier!', sq: 'Ju jeni anëtari i parë këtu!' },

  // Manager Section
  'dash.manager.title': { en: 'Your Manager', de: 'Dein Manager', sq: 'Manageri Juaj' },
  'dash.manager.none': { en: 'No Manager', de: 'Kein Manager', sq: 'Pa Manager' },
  'dash.manager.email': { en: 'Email', de: 'E-Mail', sq: 'Email' },
  'dash.manager.call': { en: 'Call', de: 'Anrufen', sq: 'Telefono' },

  // Requests Section
  'dash.requests.title': { en: 'My Inquiries', de: 'Meine Anfragen', sq: 'Kërkesat e Mia' },
  'dash.requests.new': { en: 'New Inquiry', de: 'Neue Anfrage', sq: 'Kërkesë e Re' },
  'dash.requests.type': { en: 'Type', de: 'Typ', sq: 'Lloji' },
  'dash.requests.subject': { en: 'Subject', de: 'Betreff', sq: 'Subjekti' },
  'dash.requests.message': { en: 'Message', de: 'Nachricht', sq: 'Mesazhi' },
  'dash.requests.submit': { en: 'Submit Request', de: 'Anfrage senden', sq: 'Dërgo Kërkesën' },
  'req.type.DONATION': { en: 'Donation', de: 'Spende', sq: 'Donacion' },
  'req.type.PROJECT': { en: 'Project Proposal', de: 'Projektvorschlag', sq: 'Propozim Projekti' },
  'req.type.GENERAL': { en: 'General Inquiry', de: 'Allgemein', sq: 'Të përgjithshme' },
  'req.status.OPEN': { en: 'Open', de: 'Offen', sq: 'E Hapur' },
  'req.status.IN_PROGRESS': { en: 'In Progress', de: 'In Bearbeitung', sq: 'Në Përpunim' },
  'req.status.DONE': { en: 'Resolved', de: 'Erledigt', sq: 'E Përfunduar' },
  'req.status.REJECTED': { en: 'Rejected', de: 'Abgelehnt', sq: 'E Refuzuar' },

  // Community Pulse
  'dash.community.title': { en: 'Community Pulse', de: 'Community Puls', sq: 'Pulsi i Komunitetit' },
  'dash.community.active_members': { en: 'Active members in your neighborhood', de: 'Aktive Mitglieder in deinem Quartier', sq: 'Anëtarë aktivë në lagjen tuaj' },
  'dash.community.quote': { en: 'Unity makes strength. Thank you for being part of the change!', de: 'Einigkeit macht stark. Danke, dass du Teil des Wandels bist!', sq: 'Bashkimi bën fuqinë. Faleminderit që jeni pjesë e ndryshimit!' },
  
  // --- DASHBOARD INSIGHTS ---
  'dash.insights.active': { en: 'Active Neighbors', de: 'Aktive Nachbarn', sq: 'Fqinjët Aktivë' },
  'dash.insights.participation': { en: 'Participation Rate', de: 'Beteiligungsrate', sq: 'Shkalla e Pjesëmarrjes' },
  'dash.insights.of': { en: 'of', de: 'von', sq: 'nga' },
  'dash.insights.members': { en: 'members', de: 'Mitgliedern', sq: 'anëtarë' },
  'dash.insights.desc': { en: 'Members who have paid the annual fee.', de: 'Mitglieder, die den Jahresbeitrag bezahlt haben.', sq: 'Anëtarët që kanë paguar kuotën vjetore.' },

  // --- REP DASHBOARD ---
  'rep.title': { en: 'Representative', de: 'Vertreter', sq: 'Përfaqësuesi' },
  'rep.cash_balance': { en: 'Cash Balance', de: 'Kassenbestand', sq: 'Gjendja në Kasë' },
  'rep.deposit': { en: 'Deposit to Bank', de: 'Einzahlung Bank', sq: 'Depozito në Bankë' },
  'rep.collection': { en: 'Collection', de: 'Inkasso', sq: 'Inkasimi' },
  'rep.expenses': { en: 'Expenses', de: 'Ausgaben', sq: 'Shpenzimet' },
  'rep.tasks': { en: 'Tasks', de: 'Aufgaben', sq: 'Detyrat' },
  'rep.register_member': { en: 'Register Member', de: 'Mitglied registrieren', sq: 'Regjistro Anëtar' },
  'rep.search_member': { en: 'Search member...', de: 'Mitglied suchen...', sq: 'Kërko banor...' },
  'rep.collect': { en: 'Collect Payment', de: 'Kassieren', sq: 'Arkëto' },
  'rep.paid': { en: 'Paid', de: 'Bezahlt', sq: 'Paguar' },
  'rep.new_expense': { en: 'New Expense', de: 'Neue Ausgabe', sq: 'Shto Shpenzim' },
  'rep.expense_history': { en: 'Expense History', de: 'Ausgabenhistorie', sq: 'Historiku i Shpenzimeve' },
  'rep.no_tasks': { en: 'No active tasks.', de: 'Keine aktiven Aufgaben.', sq: 'Nuk keni detyra aktive.' },

  // --- ADMIN ---
  'admin.hub.title': { en: 'Admin Hub', de: 'Admin Zentrale', sq: 'Admin Hub' },
  'admin.hub.subtitle': { en: 'Full control of the association.', de: 'Volle Kontrolle über den Verein.', sq: 'Kontrolli i plotë i shoqatës.' },
  'admin.tab.analytics': { en: 'Dashboard', de: 'Übersicht', sq: 'Pasqyra' },
  'admin.tab.users': { en: 'Members', de: 'Mitglieder', sq: 'Anëtarët' },
  'admin.tab.data_quality': { en: 'Data Quality', de: 'Datenqualität', sq: 'Cilësia e të Dhënave' },
  'admin.tab.board': { en: 'Board', de: 'Vorstand', sq: 'Kryesia' },
  'admin.tab.events': { en: 'Events', de: 'Events', sq: 'Ngjarjet' },
  'admin.tab.neighborhoods': { en: 'Neighborhoods', de: 'Quartiere', sq: 'Lagjet' },
  'admin.tab.website': { en: 'Website', de: 'Webseite', sq: 'Website' },
  'admin.tab.social': { en: 'Social AI', de: 'Social AI', sq: 'Social AI' },
  'admin.tab.finance': { en: 'Finance', de: 'Finanzen', sq: 'Financat' },
  'admin.tab.accounting': { en: 'Accounting', de: 'Buchhaltung', sq: 'Kontabiliteti' },
  'admin.tab.expenses': { en: 'Expenses', de: 'Ausgaben', sq: 'Shpenzimet' },
  'admin.tab.statistics': { en: 'Statistics', de: 'Statistiken', sq: 'Statistikat' },
  'admin.tab.settings': { en: 'Settings', de: 'Einstellungen', sq: 'Cilësimet' },
  'admin.tasks.title': { en: 'Global Tasks', de: 'Aufgaben', sq: 'Detyrat Globale' },
  'admin.tasks.none': { en: 'No pending tasks.', de: 'Keine offenen Aufgaben.', sq: 'Nuk ka detyra.' },
  
  'admin.members.title': { en: 'Member Management', de: 'Mitgliederverwaltung', sq: 'Menaxhimi i Anëtarëve' },
  'admin.members.search': { en: 'Search members...', de: 'Mitglieder suchen...', sq: 'Kërko anëtarët...' },
  'admin.members.add_new': { en: 'Add Member', de: 'Mitglied hinzufügen', sq: 'Shto Anëtar' },
  'admin.members.details': { en: 'Member Details', de: 'Mitgliederdetails', sq: 'Detajet e Anëtarit' },
  'admin.members.reminders': { en: 'Reminders', de: 'Erinnerungen', sq: 'Kujtesat' },
  'admin.members.add_reminder': { en: 'Add Reminder', de: 'Erinnerung +', sq: 'Shto Kujtesë' },
  'admin.members.internal_notes': { en: 'Internal Notes', de: 'Interne Notizen', sq: 'Shënime Interne' },
  'admin.confirm_delete': { en: 'Are you sure?', de: 'Sind Sie sicher?', sq: 'A jeni i sigurt?' },

  // --- ADMIN FINANCE ---
  'admin.finance.forecast': { en: 'Forecast & Planning', de: 'Prognose & Planung', sq: 'Parashikimi & Planifikimi' },
  'admin.finance.overview': { en: 'Overview', de: 'Übersicht', sq: 'Pasqyra' },
  'admin.finance.invoices': { en: 'Invoices & Drafts', de: 'Rechnungen & Entwürfe', sq: 'Faturat & Draftet' },
  'admin.finance.dunning': { en: 'Dunning', de: 'Mahnwesen', sq: 'Mahnwesen' },
  'admin.finance.settings': { en: 'Settings', de: 'Einstellungen', sq: 'Cilësimet' },
  'admin.finance.collected': { en: 'Total Collected', de: 'Einnahmen Total', sq: 'Të hyrat Totale' },
  'admin.finance.open': { en: 'Open Invoices', de: 'Offene Rechnungen', sq: 'Faturat e Hapura' },
  'admin.finance.overdue': { en: 'Overdue', de: 'Überfällig', sq: 'Të papaguara' },
  'admin.finance.potential': { en: 'Potential Revenue', de: 'Potenzieller Umsatz', sq: 'Të hyrat Potenciale' },
  'admin.finance.recent': { en: 'Recent Invoices', de: 'Letzte Rechnungen', sq: 'Faturat e fundit' },
  'admin.finance.invoiceNum': { en: 'Invoice #', de: 'Rechnungs-Nr.', sq: 'Nr. Faturës' },
  'admin.finance.amount': { en: 'Amount', de: 'Betrag', sq: 'Shuma' },
  'admin.finance.date': { en: 'Date', de: 'Datum', sq: 'Data' },
  'admin.finance.member': { en: 'Member', de: 'Mitglied', sq: 'Anëtari' },
  'admin.finance.status': { en: 'Status', de: 'Status', sq: 'Statusi' },
  'admin.finance.create': { en: 'Create Invoice', de: 'Rechnung erstellen', sq: 'Krijo Faturë' },
  'admin.finance.verify': { en: 'Verify Drafts', de: 'Entwürfe prüfen', sq: 'Verifiko Draftet' },
  'admin.finance.markPaid': { en: 'Mark Paid', de: 'Als bezahlt markieren', sq: 'Shëno të paguar' },

  // --- ADMIN STATISTICS ---
  'admin.stats.revenue': { en: 'Revenue', de: 'Einnahmen', sq: 'Të Hyrat' },
  'admin.stats.late': { en: 'Late Payers', de: 'Säumige Zahler', sq: 'Vonesat' },
  'admin.stats.unpaid': { en: 'Open / Unpaid', de: 'Offen / Unbezahlt', sq: 'Të Hapura' },
  'admin.stats.participation': { en: 'Avg. Participation', de: 'Durchs. Beteiligung', sq: 'Pjesëmarrja Mesatare' },
  'admin.stats.neighborhoodPerf': { en: 'Neighborhood Performance', de: 'Quartier Performance', sq: 'Performanca e Lagjeve' },
  'admin.stats.history': { en: 'Revenue Trends', de: 'Umsatzentwicklung', sq: 'Trendi i Të Hyrave' },
  'admin.stats.memberDetail': { en: 'Member Payment Detail', de: 'Mitglieder Zahlungsdetails', sq: 'Detajet e Pagesave' },
  'admin.stats.totalMembers': { en: 'Total Members', de: 'Mitglieder Total', sq: 'Gjithsej Anëtarë' },
  'admin.stats.payers': { en: 'Payers', de: 'Zahler', sq: 'Paguesit' },

  // --- ADMIN EXPENSES ---
  'admin.expenses.title': { en: 'Expenses', de: 'Ausgaben', sq: 'Shpenzimet' },
  'admin.expenses.all': { en: 'All Expenses', de: 'Alle Ausgaben', sq: 'Të Gjitha' },
  'admin.expenses.pending': { en: 'Pending / Review', de: 'Offen / Prüfung', sq: 'Në Pritje' },
  'admin.expenses.paid': { en: 'Booked', de: 'Verbucht', sq: 'Të Libruara' },
  'admin.expenses.vendor': { en: 'Vendor', de: 'Lieferant', sq: 'Furnitori' },
  'admin.expenses.description': { en: 'Description', de: 'Beschreibung', sq: 'Përshkrimi' },
  'admin.expenses.category': { en: 'Expense Account', de: 'Aufwandskonto', sq: 'Llogaria e Shpenzimit' },
  'admin.expenses.paymentAcc': { en: 'Payment Account', de: 'Zahlungskonto', sq: 'Llogaria e Pagesës' },
  'admin.expenses.scan': { en: 'Scan Receipt', de: 'Beleg Scannen', sq: 'Skano Faturën' },
  'admin.expenses.manual': { en: 'Manual Entry', de: 'Manuell', sq: 'Manuale' },
  'admin.expenses.book': { en: 'Book', de: 'Verbuchen', sq: 'Libro' },
  'admin.expenses.save': { en: 'Save Expense', de: 'Ausgabe speichern', sq: 'Ruaj Shpenzimin' },

  // --- ADMIN ACCOUNTING ---
  'admin.accounting.title': { en: 'Accounting', de: 'Buchhaltung', sq: 'Kontabiliteti' },
  'admin.accounting.balanceSheet': { en: 'Balance Sheet', de: 'Bilanz', sq: 'Bilanci' },
  'admin.accounting.incomeStatement': { en: 'Income Statement', de: 'Erfolgsrechnung', sq: 'Pasqyra e të Ardhurave' },
  'admin.accounting.journal': { en: 'Journal', de: 'Journal', sq: 'Ditari' },
  'admin.accounting.accounts': { en: 'Chart of Accounts', de: 'Kontenplan', sq: 'Plani Kontabël' },
  'admin.accounting.assets': { en: 'Assets', de: 'Aktiven', sq: 'Aktivet' },
  'admin.accounting.liabilities': { en: 'Liabilities', de: 'Passiven', sq: 'Pasivet' },
  'admin.accounting.revenue': { en: 'Revenue', de: 'Ertrag', sq: 'Të Ardhurat' },
  'admin.accounting.expense': { en: 'Expense', de: 'Aufwand', sq: 'Shpenzimet' },
  'admin.accounting.profit': { en: 'Net Profit', de: 'Jahresergebnis', sq: 'Fitimi Neto' },
  'admin.accounting.debit': { en: 'Debit', de: 'Soll', sq: 'Debi' },
  'admin.accounting.credit': { en: 'Credit', de: 'Haben', sq: 'Kredi' },
  'admin.accounting.closeYear': { en: 'Close Year', de: 'Jahr abschließen', sq: 'Mbyll Vitin' },
  'admin.accounting.newBooking': { en: 'New Booking', de: 'Neue Buchung', sq: 'Regjistrim i Ri' },
  'admin.accounting.importPayments': { en: 'Import Payments', de: 'Zahlungen importieren', sq: 'Importo Pagesat' },

  // --- EVENTS ---
  'events.title': { en: 'Upcoming Events', de: 'Kommende Events', sq: 'Ngjarjet e Ardhshme' },
  'events.subtitle': { en: 'Participate in our actions.', de: 'Nimm an unseren Aktionen teil.', sq: 'Merrni pjesë në aksionet tona.' },
  'events.desc': { 
    en: 'Discover upcoming gatherings, cultural festivals, and community projects. Be part of our vibrant network.', 
    de: 'Entdecken Sie kommende Treffen, Kulturfestivals und Gemeinschaftsprojekte. Werden Sie Teil unseres lebendigen Netzwerks.', 
    sq: 'Zbuloni tubimet e ardhshme, festivalet kulturore dhe projektet komunitare. Bëhuni pjesë e rrjetit tonë të gjallë.' 
  },
  'events.view_all': { en: 'View All', de: 'Alle ansehen', sq: 'Shiko të gjitha' },
  'events.join': { en: 'Join', de: 'Teilnehmen', sq: 'Bashkohu' },

  // --- FIELDS & STATUS ---
  'field.salutation': { en: 'Salutation', de: 'Anrede', sq: 'Përshëndetja' },
  'field.firstName': { en: 'First Name', de: 'Vorname', sq: 'Emri' },
  'field.lastName': { en: 'Last Name', de: 'Nachname', sq: 'Mbiemri' },
  'field.email': { en: 'Email', de: 'E-Mail', sq: 'Email' },
  'field.phone': { en: 'Phone', de: 'Telefon', sq: 'Telefoni' },
  'field.street': { en: 'Street', de: 'Strasse', sq: 'Rruga' },
  'field.zip': { en: 'ZIP', de: 'PLZ', sq: 'Kodi Postar' },
  'field.city': { en: 'City', de: 'Ort', sq: 'Qyteti' },
  'field.country': { en: 'Country', de: 'Land', sq: 'Shteti' },
  'field.birthdate': { en: 'Birthdate', de: 'Geburtsdatum', sq: 'Datëlindja' },
  'field.category': { en: 'Category', de: 'Kategorie', sq: 'Kategoria' },
  'field.status': { en: 'Status', de: 'Status', sq: 'Statusi' },

  'status.active': { en: 'Active', de: 'Aktiv', sq: 'Aktiv' },
  'status.pending': { en: 'Pending', de: 'Ausstehend', sq: 'Në pritje' },
  'status.inactive': { en: 'Inactive', de: 'Inaktiv', sq: 'Joaktiv' },
  'status.all': { en: 'All', de: 'Alle', sq: 'Të gjitha' },

  'cat.individual': { en: 'Individual', de: 'Einzelperson', sq: 'Individual' },
  'cat.family': { en: 'Family', de: 'Familie', sq: 'Familjar' },
  'cat.donor': { en: 'Donor', de: 'Spender', sq: 'Donator' },

  'btn.save': { en: 'Save', de: 'Speichern', sq: 'Ruaj' },
};

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string, params?: Record<string, string | number>) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguage] = useState<Language>(() => {
    const saved = localStorage.getItem('koretini_lang');
    if (saved === 'en' || saved === 'de' || saved === 'sq') return saved;
    return 'sq'; 
  });

  useEffect(() => {
    localStorage.setItem('koretini_lang', language);
    document.documentElement.lang = language;
  }, [language]);

  const t = (key: string, params?: Record<string, string | number>) => {
    let text = translations[key]?.[language] || key;
    if (params) {
        Object.keys(params).forEach(param => {
            text = text.replace(`{${param}}`, String(params[param]));
        });
    }
    return text;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useTranslation = () => {
  const context = useContext(LanguageContext);
  if (!context) throw new Error('useTranslation must be used within a LanguageProvider');
  return context;
};
