
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Mail, Plus, BarChart2, Trash2, Send, HelpCircle, CheckCircle2, MessageSquare, X, Handshake, Globe, Phone } from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc, updateDoc } from '@/services/supabase-bridge';
import { Poll, Inquiry } from '../types';
import { packageByKey } from '../lib/sponsorPackages';
import { useFeedback } from '../context/FeedbackContext';
import { sendEmail } from '../services/mailService';
import { useTranslation } from '../context/LanguageContext';

const AdminCommunication: React.FC = () => {
    const { t } = useTranslation();
    const { showAlert, showConfirm, showPrompt } = useFeedback();
    const [activeTab, setActiveTab] = useState<'REQUESTS' | 'SPONSORS' | 'POLLS' | 'EMAIL'>('REQUESTS');
    const [polls, setPolls] = useState<Poll[]>([]);
    const [inquiries, setInquiries] = useState<Inquiry[]>([]);
    const [sponsors, setSponsors] = useState<any[]>([]);
    
    // Poll State
    const [newPollQuestion, setNewPollQuestion] = useState('');
    const [newPollOptions, setNewPollOptions] = useState(['Yes', 'No']);

    // Email State
    const [emailSubject, setEmailSubject] = useState('');
    const [emailBody, setEmailBody] = useState('');

    useEffect(() => {
        const qSponsors = query(collection(db, 'sponsors'), orderBy('createdAt', 'desc'));
        const unsubSponsors = onSnapshot(qSponsors, (snap) => {
            setSponsors(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        }, (e) => console.error('[AdminCommunication] Sponsoren laden fehlgeschlagen:', e));

        const qPolls = query(collection(db, 'polls'), orderBy('createdAt', 'desc'));
        const unsubPolls = onSnapshot(qPolls, (snap) => {
            setPolls(snap.docs.map(d => ({ id: d.id, ...d.data() } as Poll)));
        });

        const qInquiries = query(collection(db, 'inquiries'), orderBy('createdAt', 'desc'));
        const unsubInquiries = onSnapshot(qInquiries, (snap) => {
            setInquiries(snap.docs.map(d => ({ id: d.id, ...d.data() } as Inquiry)));
        });

        return () => { unsubPolls(); unsubInquiries(); unsubSponsors(); };
    }, []);

    const createPoll = async () => {
        if (!newPollQuestion || newPollOptions.some(o => !o)) return;
        
        await addDoc(collection(db, 'polls'), {
            question: newPollQuestion,
            options: newPollOptions.map(o => ({ id: Math.random().toString(36).substr(2, 9), text: o, votes: 0 })),
            active: true,
            allowMultiple: false,
            createdBy: auth.currentUser?.uid,
            createdAt: serverTimestamp(),
            userVotes: []
        });
        setNewPollQuestion('');
        setNewPollOptions(['Yes', 'No']);
        showAlert({ type: 'success', message: t('comm.poll_created') });
    };

    const deletePoll = async (id: string) => {
        if(await showConfirm({ title: t('comm.poll_delete'), message: t('admin.confirm_delete'), type: "danger" })) {
            await deleteDoc(doc(db, 'polls', id));
        }
    };

    const handleSendNewsletter = async () => {
        if (!emailSubject || !emailBody) return;
        const confirmed = await showConfirm({ 
            title: t('comm.newsletter_title'), 
            message: t('comm.newsletter_confirm'), 
            type: "danger" 
        });
        if (!confirmed) return;

        try {
            await sendEmail({
                to: auth.currentUser?.email || '',
                subject: emailSubject,
                html: emailBody
            });
            showAlert({ type: 'success', message: t('comm.newsletter_queued') });
        } catch (e) {
            showAlert({ type: 'error', message: t('comm.failed') });
        }
    };

    // --- REQUESTS LOGIC ---
    const updateRequestStatus = async (inquiry: Inquiry, status: Inquiry['status']) => {
        await updateDoc(doc(db, 'inquiries', inquiry.id), { status });
    };

    const addAdminNote = async (inquiry: Inquiry) => {
        const note = await showPrompt({
            title: t('comm.note_title'),
            message: t('comm.note_text'),
            placeholder: "e.g. We will discuss this in the next meeting."
        });
        if (note) {
            await updateDoc(doc(db, 'inquiries', inquiry.id), { adminNote: note });
        }
    };

    const updateSponsorStatus = async (id: string, status: string) => {
        try {
            await updateDoc(doc(db, 'sponsors', id), { status, updatedAt: new Date().toISOString() } as any);
            showAlert({ type: 'success', message: t('admin.sponsors.saved') });
        } catch (e: any) {
            showAlert({ type: 'error', message: t('admin.save_failed', { reason: e?.message || '?' }) });
        }
    };

    // Nur zugesagte Beitraege zaehlen -- eine Anfrage ist noch kein Geld.
    const sponsorTotal = sponsors
        .filter(sp => sp.status === 'CONFIRMED')
        .reduce((sum, sp) => sum + (Number(sp.amount) || 0), 0);

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm min-h-[600px] overflow-hidden flex flex-col">
            <div className="flex border-b border-stone-100">
                <button onClick={() => setActiveTab('REQUESTS')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'REQUESTS' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><HelpCircle size={16}/> Requests ({inquiries.filter(i => i.status === 'OPEN').length})</button>
                <button onClick={() => setActiveTab('SPONSORS')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'SPONSORS' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><Handshake size={16}/> {t('admin.tab.sponsors')}{sponsors.length > 0 && <span className="text-[10px] bg-primary text-white rounded-full px-1.5 py-0.5">{sponsors.length}</span>}</button>
                <button onClick={() => setActiveTab('POLLS')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'POLLS' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><BarChart2 size={16}/> {t('comm.polls')}</button>
                <button onClick={() => setActiveTab('EMAIL')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'EMAIL' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><Mail size={16}/> {t('comm.newsletter')}</button>
            </div>

            <div className="p-8 flex-1 overflow-y-auto bg-[#faf9f6]">
                
                {activeTab === 'SPONSORS' && (
                    <div className="space-y-4">
                        <div className="flex flex-wrap justify-between items-center gap-3 bg-white p-5 rounded-2xl border border-stone-100">
                            <h3 className="font-bold text-stone-900 flex items-center gap-2"><Handshake size={18} className="text-primary"/> {t('admin.sponsors.title')}</h3>
                            <div className="text-right">
                                <p className="text-[10px] font-bold text-stone-400 uppercase tracking-widest">{t('admin.sponsors.total')}</p>
                                <p className="font-bold text-xl text-stone-900">CHF {sponsorTotal.toLocaleString()}</p>
                            </div>
                        </div>

                        {sponsors.length === 0 && (
                            <div className="text-center py-12 bg-white rounded-2xl border border-dashed border-stone-200">
                                <p className="text-stone-400 italic text-sm">{t('admin.sponsors.none')}</p>
                            </div>
                        )}

                        {sponsors.map(sp => {
                            const pkg = packageByKey(sp.packageKey);
                            return (
                                <div key={sp.id} className="bg-white p-6 rounded-2xl border border-stone-100 shadow-sm">
                                    <div className="flex flex-wrap justify-between items-start gap-4 mb-4">
                                        <div>
                                            <h4 className="font-bold text-stone-900 text-lg">{sp.company}</h4>
                                            <p className="text-xs text-stone-500">
                                                {sp.contactName} · {sp.createdAt ? new Date(sp.createdAt).toLocaleDateString() : ''}
                                            </p>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <span className="text-sm font-bold text-stone-900 whitespace-nowrap">
                                                {pkg ? t(pkg.titleKey) : sp.packageKey}{sp.amount ? ` · CHF ${Number(sp.amount).toLocaleString()}` : ''}
                                            </span>
                                            <select
                                                value={sp.status}
                                                onChange={(e) => updateSponsorStatus(sp.id, e.target.value)}
                                                className={`text-xs font-bold rounded-lg py-1.5 px-2 outline-none border cursor-pointer ${
                                                    sp.status === 'CONFIRMED' ? 'bg-green-50 border-green-200 text-green-700'
                                                    : sp.status === 'DECLINED' ? 'bg-red-50 border-red-200 text-red-600'
                                                    : sp.status === 'IN_PROGRESS' ? 'bg-amber-50 border-amber-200 text-amber-700'
                                                    : 'bg-stone-50 border-stone-200 text-stone-600'}`}
                                            >
                                                <option value="NEW">{t('admin.sponsors.status.NEW')}</option>
                                                <option value="IN_PROGRESS">{t('admin.sponsors.status.IN_PROGRESS')}</option>
                                                <option value="CONFIRMED">{t('admin.sponsors.status.CONFIRMED')}</option>
                                                <option value="DECLINED">{t('admin.sponsors.status.DECLINED')}</option>
                                            </select>
                                        </div>
                                    </div>

                                    <div className="flex flex-wrap gap-x-6 gap-y-2 text-xs text-stone-500 mb-3">
                                        <a href={`mailto:${sp.email}`} className="flex items-center gap-1.5 hover:text-primary"><Mail size={12}/> {sp.email}</a>
                                        {sp.phone && <span className="flex items-center gap-1.5"><Phone size={12}/> {sp.phone}</span>}
                                        {sp.website && <a href={sp.website} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1.5 hover:text-primary"><Globe size={12}/> {sp.website}</a>}
                                        {(sp.street || sp.city) && <span>{[sp.street, sp.zip, sp.city, sp.country].filter(Boolean).join(', ')}</span>}
                                    </div>

                                    {sp.message && (
                                        <div className="bg-stone-50 p-4 rounded-xl text-sm text-stone-600 leading-relaxed">{sp.message}</div>
                                    )}
                                </div>
                            );
                        })}
                    </div>
                )}

                {activeTab === 'REQUESTS' && (
                    <div className="space-y-4">
                        {inquiries.map(req => (
                            <div key={req.id} className="bg-white p-6 rounded-2xl border border-stone-100 shadow-sm">
                                <div className="flex justify-between items-start mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className={`p-2 rounded-xl ${req.type === 'DONATION' ? 'bg-green-100 text-green-600' : 'bg-blue-100 text-blue-600'}`}>
                                            <MessageSquare size={18} />
                                        </div>
                                        <div>
                                            <h4 className="font-bold text-stone-900">{req.subject}</h4>
                                            <p className="text-xs text-stone-500">{req.userName} • {req.createdAt?.toDate().toLocaleDateString()}</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        <select 
                                            value={req.status} 
                                            onChange={(e) => updateRequestStatus(req, e.target.value as any)}
                                            className={`text-xs font-bold rounded-lg py-1 px-2 outline-none border cursor-pointer ${req.status === 'DONE' ? 'bg-green-50 border-green-200 text-green-700' : req.status === 'REJECTED' ? 'bg-red-50 border-red-200 text-red-700' : 'bg-white border-stone-200 text-stone-600'}`}
                                        >
                                            <option value="OPEN">{t('inq.open')}</option>
                                            <option value="IN_PROGRESS">{t('inq.in_progress')}</option>
                                            <option value="DONE">{t('inq.done')}</option>
                                            <option value="REJECTED">{t('inq.rejected')}</option>
                                        </select>
                                    </div>
                                </div>
                                <div className="bg-stone-50 p-4 rounded-xl text-sm text-stone-600 leading-relaxed mb-4">
                                    {req.message}
                                </div>
                                {req.adminNote && (
                                    <div className="mb-4 pl-3 border-l-2 border-primary">
                                        <p className="text-xs text-stone-400 font-bold uppercase tracking-wide">{t('comm.admin_response')}</p>
                                        <p className="text-sm text-stone-600 italic">{req.adminNote}</p>
                                    </div>
                                )}
                                <div className="flex justify-end">
                                    <button onClick={() => addAdminNote(req)} className="text-xs font-bold text-stone-400 hover:text-primary transition-colors">
                                        {req.adminNote ? t('comm.edit_response') : t('comm.add_response')}
                                    </button>
                                </div>
                            </div>
                        ))}
                        {inquiries.length === 0 && <p className="text-center text-stone-400 italic">{t('comm.no_inquiries')}</p>}
                    </div>
                )}

                {activeTab === 'POLLS' && (
                    <div className="space-y-8">
                        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                            <h4 className="font-bold mb-4">{t('comm.new_poll')}</h4>
                            <input 
                                value={newPollQuestion}
                                onChange={e => setNewPollQuestion(e.target.value)}
                                placeholder={t('comm.question_ph')}
                                className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl mb-4 outline-none"
                            />
                            {newPollOptions.map((opt, i) => (
                                <input 
                                    key={i}
                                    value={opt}
                                    onChange={e => {
                                        const newOpts = [...newPollOptions];
                                        newOpts[i] = e.target.value;
                                        setNewPollOptions(newOpts);
                                    }}
                                    className="w-full p-2 bg-stone-50 border border-stone-200 rounded-lg mb-2 text-sm outline-none"
                                    placeholder={`Option ${i+1}`}
                                />
                            ))}
                            <div className="flex gap-2 mt-2">
                                <button onClick={() => setNewPollOptions([...newPollOptions, ''])} className="text-xs font-bold text-stone-400 hover:text-stone-600">+ Add Option</button>
                            </div>
                            <button onClick={createPoll} className="mt-4 w-full bg-stone-900 text-white py-3 rounded-xl font-bold hover:bg-black transition-all">{t('comm.launch_poll')}</button>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {polls.map(poll => (
                                <div key={poll.id} className="bg-white border border-stone-200 p-4 rounded-2xl shadow-sm">
                                    <div className="flex justify-between items-start mb-4">
                                        <h5 className="font-bold text-stone-800">{poll.question}</h5>
                                        <button onClick={() => deletePoll(poll.id)} className="text-stone-300 hover:text-red-500"><Trash2 size={16}/></button>
                                    </div>
                                    <div className="space-y-2">
                                        {poll.options.map(opt => {
                                            const total = poll.options.reduce((acc, o) => acc + o.votes, 0);
                                            const percent = total > 0 ? Math.round((opt.votes / total) * 100) : 0;
                                            return (
                                                <div key={opt.id}>
                                                    <div className="flex justify-between text-xs mb-1">
                                                        <span>{opt.text}</span>
                                                        <span className="font-bold">{opt.votes} ({percent}%)</span>
                                                    </div>
                                                    <div className="h-2 bg-stone-100 rounded-full overflow-hidden">
                                                        <div className="h-full bg-primary" style={{ width: `${percent}%` }} />
                                                    </div>
                                                </div>
                                            )
                                        })}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {activeTab === 'EMAIL' && (
                    <div className="max-w-2xl mx-auto space-y-6 bg-white p-8 rounded-[2rem] border border-stone-100 shadow-sm">
                        <div>
                            <label className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('comm.subject')}</label>
                            <input value={emailSubject} onChange={e => setEmailSubject(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl mt-1 font-bold outline-none" />
                        </div>
                        <div>
                            <label className="text-xs font-bold text-stone-400 uppercase tracking-widest">{t('comm.message_html')}</label>
                            <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl mt-1 h-64 font-mono text-sm outline-none" />
                        </div>
                        <button onClick={handleSendNewsletter} className="w-full bg-primary text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-rose-600 transition-colors shadow-lg">
                            <Send size={18} /> {t('comm.send_all')}
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AdminCommunication;
