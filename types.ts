
export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN', // Platform owner (You)
  ADMIN = 'ADMIN', // Association President
  BOARD = 'BOARD', // New: Vorstand / Board Member
  NEIGHBORHOOD_MANAGER = 'NEIGHBORHOOD_MANAGER',
  REPRESENTATIVE = 'REPRESENTATIVE', // New: Local Representative in Koretin
  MEMBER = 'MEMBER',
  GUEST = 'GUEST'
}

// --- SAAS / MULTI-TENANCY ---

export interface Tenant {
  id: string; // The subdomain (e.g., 'koretini')
  name: string;
  slug: string;
  logoUrl?: string;
  primaryColor?: string;
  secondaryColor?: string;
  subscriptionPlan: 'FREE' | 'PRO' | 'ENTERPRISE';
  subscriptionStatus: 'ACTIVE' | 'PAST_DUE' | 'CANCELLED';
  stripeCustomerId?: string;
  createdAt: string;
  contactEmail: string;
  memberCount?: number;
}

export interface UserReminder {
  id: string;
  text: string;
  date: string;
  completed: boolean;
  createdAt: string;
}

export type BillingGroup = 'STANDARD' | 'KOSOVO' | 'REDUCED';

export interface UserProfile {
  id: string;
  tenantId: string; // Critical for data separation
  email: string;
  role: UserRole;
  isBoardMember?: boolean;
  displayName?: string;
  firstName?: string;
  lastName?: string;
  salutation?: string;
  birthdate?: string;
  membershipCategory?: 'INDIVIDUAL' | 'FAMILY' | 'DONOR';
  membershipStatus: 'ACTIVE' | 'PENDING' | 'INACTIVE';
  
  // Financial Settings
  invoiceDeliveryMethod?: 'EMAIL' | 'POST' | 'BOTH';
  billingGroup?: BillingGroup; // New: Determines the fee amount automatically
  customAnnualFee?: number; // Override specific to user (optional)
  
  neighborhoodId?: string;
  familyId?: string; // New field for grouping families
  migrationRequired?: string; // Flag for admin to migrate foreign keys from old ID
  livesInKoretin?: boolean;
  joinedAt: string;
  profileComplete?: boolean;
  dataUpdateRequested?: boolean; // New: Flag to prompt user to update data
  address?: string;
  street?: string;
  zip?: string;
  city?: string;
  country?: string;
  phone?: string;
  phoneSecondary?: string;
  currency?: string;
  photoFileName?: string;
  internalNotes?: string;
  reminders?: UserReminder[];
}

export interface BoardMember {
  id: string;
  userId: string;
  role: string;
  quote: string;
  image?: string;
  createdAt: any;
}

export interface Neighborhood {
  id: string;
  tenantId?: string;
  name: string;
  description?: string;
  location: {
    lat: number;
    lng: number;
    city: string;
    country: string;
  };
  managerId?: string;
  memberCount: number;
  contactPerson: string; // Kept for backward compatibility (display string)
  contactPersonIds?: string[]; // New: List of User IDs
  contactEmail: string;
  contactPhone?: string;
  website?: string;
  image?: string;
  status: 'ACTIVE' | 'INACTIVE';
  createdAt: string;
  lastActivity: string;
}

export interface Payment {
  id: string;
  tenantId?: string;
  userId: string; // If 'EXTERNAL', check customRecipient
  neighborhoodId?: string; // Denormalized for manager queries
  amount: number;
  currency: string;
  type: 'FEE' | 'DONATION';
  invoiceType?: 'MEMBERSHIP' | 'OTHER'; // Distinguish invoice purpose
  billingYear?: number; // Only for membership fees
  
  // New field for external recipients
  customRecipient?: {
    name: string;
    address: string; // Full address string or street
    street?: string;
    zip?: string;
    city?: string;
    country?: string;
    email?: string;
  };

  method: 'PAYPAL' | 'BANK_TRANSFER' | 'QR_BILL' | 'CASH' | 'TWINT' | 'GIRO_CODE'; // Added CASH, TWINT, GIRO_CODE
  status: 'DRAFT' | 'SCHEDULED' | 'SENT' | 'PAID' | 'PENDING' | 'OVERDUE' | 'CANCELLED' | 'WRITTEN_OFF';
  deliveryMethod?: 'EMAIL' | 'POST';
  scheduledDate?: string; // ISO Date when it should be sent
  dunningLevel?: 0 | 1 | 2 | 3;
  lastDunningDate?: string;
  timestamp: any;
  dueDate?: string;
  paidAt?: string;
  invoiceNumber?: string;
  reference?: string;
  description?: string;
  pdfUrl?: string;
  bookedInJournal?: boolean;
  collectedBy?: string; // New: ID of the representative who collected the cash
}

export interface Expense {
  id: string;
  tenantId?: string;
  vendor: string;
  description: string;
  amount: number;
  currency: string;
  date: string; // Document date
  dueDate?: string;
  categoryAccountCode: string; // e.g. "4000"
  paymentAccountCode: string; // e.g. "1020" (Bank) or "1000" (Kasse)
  status: 'PENDING' | 'APPROVED' | 'PAID';
  receiptUrl?: string;
  bookedInJournal?: boolean;
  createdAt: any;
  createdBy?: string; // Who created this expense
}

export interface Poll {
  id: string;
  tenantId?: string;
  question: string;
  options: { id: string; text: string; votes: number }[];
  active: boolean;
  allowMultiple: boolean;
  createdBy: string;
  createdAt: any;
  expiresAt?: string;
  userVotes?: string[];
}

export interface Task {
  id: string;
  tenantId?: string;
  title: string;
  description?: string;
  status: 'TODO' | 'IN_PROGRESS' | 'DONE';
  priority: 'LOW' | 'MEDIUM' | 'HIGH';
  assignedTo?: string[]; // User IDs
  assignedToName?: string;
  dueDate?: string;
  createdBy: string;
  createdAt: any;
  sourceMeetingId?: string; // Link back to meeting
}

export interface ProtocolAttendee {
  userId: string;
  name: string;
  role: string;
  present: boolean;
}

export interface ProtocolAgendaItem {
  id: string;
  title: string; // Tema
  responsible: string; // Përgjegjësi (Text name)
  dueDate: string; // Data per tu kry
  content: string; // HTML WYSIWYG content
  linkedTaskIds?: string[]; // IDs of tasks created from this item
}

export interface BoardMeeting {
  id: string;
  tenantId?: string;
  title: string;
  date: string;
  location?: string;
  attendees: ProtocolAttendee[];
  agendaItems: ProtocolAgendaItem[];
  status: 'PLANNED' | 'COMPLETED';
  documents?: string[];
}

export interface GeneralAssembly {
  id: string;
  tenantId?: string;
  year: number;
  date: string;
  status: 'PLANNED' | 'LIVE' | 'COMPLETED';
  activeSlideIndex?: number;
  agenda: string[];
}

export interface FeeStructure {
    STANDARD: { amount: number, currency: string, label: string };
    KOSOVO: { amount: number, currency: string, label: string };
    REDUCED: { amount: number, currency: string, label: string };
}

export interface GlobalPaymentSettings {
  iban: string;
  bankName: string;
  bic: string;
  accountHolder: string;
  street: string;
  zip: string;
  city: string;
  country: string;
  paypalEmail: string;
  currency: string;
  annualFeeAmount: number; // Legacy, keep for fallback
  fees?: FeeStructure; // New structure
  qrIban?: string;
  qrReferenceId?: string;
  twintUrl?: string;
  twintNumber?: string; // New: TWINT Number
  twintQrImage?: string; // New: Custom image upload for Twint
  paypalClientId?: string; // New: PayPal Client ID
  paypalSecret?: string; // New: PayPal Secret
  paymentTermsDays?: number; // New: Days until due
  dunningDelayDays?: number; // New: Days after due date before dunning
  // Added contactEmail to fix errors in Dashboard.tsx and AdminFinance.tsx
  contactEmail?: string;
}

export interface SystemSettings {
  maintenanceMode: boolean;
  allowRegistration: boolean;
  modules: {
    villageLive: boolean;
    events: boolean;
    news: boolean;
  };
  systemEmail: string;
}

export type ContentStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export interface SolidarityEvent {
  id: string;
  tenantId?: string;
  title: string;
  description: string;
  date: string;
  time: string;
  location: string;
  image: string;
  images?: string[];
  category: 'HEALTH' | 'EDUCATION' | 'CULTURE' | 'SPORT' | 'SOCIAL';
  status: ContentStatus; // Updated: From lifecycle status
  isFeatured: boolean;
  isRegistrable: boolean; 
  createdAt: any;
}

export interface EventRegistration {
  id: string;
  eventId: string;
  eventTitle: string;
  userId?: string;
  name: string;
  email: string;
  phone?: string;
  type: 'MEMBER' | 'GUEST';
  registeredAt: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED'; 
}

export interface SocialPost {
  id: string;
  tenantId?: string;
  content: string;
  platforms: ('FACEBOOK' | 'INSTAGRAM')[];
  scheduledTime: string;
  status: 'DRAFT' | 'SCHEDULED' | 'PUBLISHED';
  aiGenerated: boolean;
  imagePrompt?: string;
  timestamp?: any;
  image?: string | null;
}

export interface NewsArticle {
  id: string;
  tenantId?: string;
  title: string;
  category: string;
  subcategory: string;
  location: string;
  image: string;
  content: string[];
  status: ContentStatus; // New: Lifecycle status
  publishAt?: any; // New: For scheduling news
  timestamp: any;
  gradientColors?: string[];
}

export type AccountClass = 'ASSET' | 'LIABILITY' | 'REVENUE' | 'EXPENSE';

export interface Account {
  id: string;
  code: string;
  name: string;
  class: AccountClass; 
  category: string;
  systemAccount?: boolean;
}

export interface JournalEntry {
  id: string;
  tenantId?: string;
  date: string;
  description: string;
  debitCode: string;
  creditCode: string;
  amount: number;
  referenceId?: string;
  createdAt: any;
  isSystemEntry?: boolean;
}

export interface FiscalYear {
  id: string;
  tenantId?: string;
  year: number;
  status: 'OPEN' | 'CLOSED';
  closedAt?: string;
  netProfit?: number;
}

// NEW: Request/Inquiry Interface
export interface Inquiry {
  id: string;
  userId: string;
  userName: string;
  type: 'DONATION' | 'PROJECT' | 'GENERAL';
  subject: string;
  message: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'DONE' | 'REJECTED';
  adminNote?: string;
  createdAt: any;
  updatedAt?: any;
}
