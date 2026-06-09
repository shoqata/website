
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Mail, Plus, BarChart2, Trash2, Send, HelpCircle, CheckCircle2, MessageSquare, X } from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { Poll, Inquiry } from '../types';
import { useFeedback } from '../context/FeedbackContext';
import { sendEmail } from '../services/mailService';
import { useTranslation } from '../context/LanguageContext';

const AdminCommunication: React.FC = () => {
    const { t } = useTranslation();
    const { showAlert, showConfirm, showPrompt } = useFeedback();
    const [activeTab, setActiveTab] = useState<'REQUESTS' | 'POLLS' | 'EMAIL'>('REQUESTS');
    const [polls, setPolls] = useState<Poll[]>([]);
    const [inquiries, setInquiries] = useState<Inquiry[]>([]);
    
    // Poll State
    const [newPollQuestion, setNewPollQuestion] = useState('');
    const [newPollOptions, setNewPollOptions] = useState(['Yes', 'No']);

    // Email State
    const [emailSubject, setEmailSubject] = useState('');
    const [emailBody, setEmailBody] = useState('');

    useEffect(() => {
        const qPolls = query(collection(db, 'polls'), orderBy('createdAt', 'desc'));
        const unsubPolls = onSnapshot(qPolls, (snap) => {
            setPolls(snap.docs.map(d => ({ id: d.id, ...d.data() } as Poll)));
        });

        const qInquiries = query(collection(db, 'inquiries'), orderBy('createdAt', 'desc'));
        const unsubInquiries = onSnapshot(qInquiries, (snap) => {
            setInquiries(snap.docs.map(d => ({ id: d.id, ...d.data() } as Inquiry)));
        });

        return () => { unsubPolls(); unsubInquiries(); };
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
        showAlert({ type: 'success', message: "Poll created!" });
    };

    const deletePoll = async (id: string) => {
        if(await showConfirm({ title: "Delete Poll", message: "Sure?", type: "danger" })) {
            await deleteDoc(doc(db, 'polls', id));
        }
    };

    const handleSendNewsletter = async () => {
        if (!emailSubject || !emailBody) return;
        const confirmed = await showConfirm({ 
            title: "Send Newsletter", 
            message: "This will send emails to ALL members. Are you sure?", 
            type: "danger" 
        });
        if (!confirmed) return;

        try {
            await sendEmail({
                to: auth.currentUser?.email || '',
                subject: emailSubject,
                html: emailBody
            });
            showAlert({ type: 'success', message: "Newsletter queued (Test sent to admin)." });
        } catch (e) {
            showAlert({ type: 'error', message: "Failed." });
        }
    };

    // --- REQUESTS LOGIC ---
    const updateRequestStatus = async (inquiry: Inquiry, status: Inquiry['status']) => {
        await updateDoc(doc(db, 'inquiries', inquiry.id), { status });
    };

    const addAdminNote = async (inquiry: Inquiry) => {
        const note = await showPrompt({
            title: "Add Admin Note",
            message: "This note will be visible to the user.",
            placeholder: "e.g. We will discuss this in the next meeting."
        });
        if (note) {
            await updateDoc(doc(db, 'inquiries', inquiry.id), { adminNote: note });
        }
    };

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm min-h-[600px] overflow-hidden flex flex-col">
            <div className="flex border-b border-stone-100">
                <button onClick={() => setActiveTab('REQUESTS')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'REQUESTS' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><HelpCircle size={16}/> Requests ({inquiries.filter(i => i.status === 'OPEN').length})</button>
                <button onClick={() => setActiveTab('POLLS')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'POLLS' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><BarChart2 size={16}/> Polls</button>
                <button onClick={() => setActiveTab('EMAIL')} className={`flex-1 py-4 text-sm font-bold flex items-center justify-center gap-2 ${activeTab === 'EMAIL' ? 'bg-stone-50 text-primary' : 'text-stone-400'}`}><Mail size={16}/> Newsletter</button>
            </div>

            <div className="p-8 flex-1 overflow-y-auto bg-[#faf9f6]">
                
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
                                            <option value="OPEN">Open</option>
                                            <option value="IN_PROGRESS">In Progress</option>
                                            <option value="DONE">Done</option>
                                            <option value="REJECTED">Rejected</option>
                                        </select>
                                    </div>
                                </div>
                                <div className="bg-stone-50 p-4 rounded-xl text-sm text-stone-600 leading-relaxed mb-4">
                                    {req.message}
                                </div>
                                {req.adminNote && (
                                    <div className="mb-4 pl-3 border-l-2 border-primary">
                                        <p className="text-xs text-stone-400 font-bold uppercase tracking-wide">Admin Response</p>
                                        <p className="text-sm text-stone-600 italic">{req.adminNote}</p>
                                    </div>
                                )}
                                <div className="flex justify-end">
                                    <button onClick={() => addAdminNote(req)} className="text-xs font-bold text-stone-400 hover:text-primary transition-colors">
                                        {req.adminNote ? 'Edit Response' : '+ Add Response'}
                                    </button>
                                </div>
                            </div>
                        ))}
                        {inquiries.length === 0 && <p className="text-center text-stone-400 italic">No inquiries found.</p>}
                    </div>
                )}

                {activeTab === 'POLLS' && (
                    <div className="space-y-8">
                        <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                            <h4 className="font-bold mb-4">Create New Poll</h4>
                            <input 
                                value={newPollQuestion}
                                onChange={e => setNewPollQuestion(e.target.value)}
                                placeholder="Question (e.g. Should we renovate the school?)"
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
                            <button onClick={createPoll} className="mt-4 w-full bg-stone-900 text-white py-3 rounded-xl font-bold hover:bg-black transition-all">Launch Poll</button>
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
                            <label className="text-xs font-bold text-stone-400 uppercase tracking-widest">Subject</label>
                            <input value={emailSubject} onChange={e => setEmailSubject(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl mt-1 font-bold outline-none" />
                        </div>
                        <div>
                            <label className="text-xs font-bold text-stone-400 uppercase tracking-widest">Message (HTML supported)</label>
                            <textarea value={emailBody} onChange={e => setEmailBody(e.target.value)} className="w-full p-4 bg-stone-50 border border-stone-200 rounded-xl mt-1 h-64 font-mono text-sm outline-none" />
                        </div>
                        <button onClick={handleSendNewsletter} className="w-full bg-primary text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 hover:bg-rose-600 transition-colors shadow-lg">
                            <Send size={18} /> Send to All Members
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AdminCommunication;
