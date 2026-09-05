
import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { FileText, Calendar, Users, Plus, Save, Trash2, CheckCircle2, X, Bold, Italic, List, AlignLeft, User, Upload, Briefcase, UserPlus, CheckSquare, ArrowRight, Loader2, Link as LinkIcon, AlertCircle, Printer, Share2, Download, Eye, RefreshCw } from 'lucide-react';
import { db, storage, auth } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, doc, updateDoc, deleteDoc, serverTimestamp } from '@/services/supabase-bridge';
import { ref, uploadBytes, getDownloadURL } from '@/services/supabase-bridge';
import { BoardMeeting, UserProfile, BoardMember, ProtocolAttendee, ProtocolAgendaItem, Task } from '../types';
import { useFeedback } from '../context/FeedbackContext';

interface AdminBoardProps {
    users: UserProfile[];
}

// --- WYSIWYG EDITOR COMPONENT ---
const RichTextEditor = ({ value, onChange, placeholder }: { value: string, onChange: (val: string) => void, placeholder?: string }) => {
    const contentRef = useRef<HTMLDivElement>(null);

    const exec = (command: string) => {
        document.execCommand(command, false);
    };

    const handleInput = () => {
        if (contentRef.current) {
            onChange(contentRef.current.innerHTML);
        }
    };

    // Sync external value changes (initial load)
    useEffect(() => {
        if (contentRef.current && contentRef.current.innerHTML !== value) {
            contentRef.current.innerHTML = value;
        }
    }, [value]); // Only re-run if value specifically changes from outside

    return (
        <div className="border border-stone-200 rounded-xl overflow-hidden bg-white">
            <div className="flex gap-2 p-2 bg-stone-50 border-b border-stone-100">
                <button onClick={() => exec('bold')} className="p-1.5 rounded hover:bg-stone-200 text-stone-600" title="Bold"><Bold size={14}/></button>
                <button onClick={() => exec('italic')} className="p-1.5 rounded hover:bg-stone-200 text-stone-600" title="Italic"><Italic size={14}/></button>
                <div className="w-px bg-stone-300 mx-1 h-6 self-center" />
                <button onClick={() => exec('insertUnorderedList')} className="p-1.5 rounded hover:bg-stone-200 text-stone-600" title="Bullet List"><List size={14}/></button>
            </div>
            <div 
                ref={contentRef}
                className="p-4 min-h-[150px] outline-none text-sm leading-relaxed prose prose-sm max-w-none empty:before:content-[attr(data-placeholder)] empty:before:text-stone-400"
                contentEditable
                onInput={handleInput}
                data-placeholder={placeholder}
            />
        </div>
    );
};

const AdminBoard: React.FC<AdminBoardProps> = ({ users }) => {
    const { showAlert, showConfirm } = useFeedback();
    const [activeTab, setActiveTab] = useState<'PROTOCOLS' | 'MEMBERS'>('PROTOCOLS');
    
    // Protocol State
    const [meetings, setMeetings] = useState<BoardMeeting[]>([]);
    const [selectedMeeting, setSelectedMeeting] = useState<BoardMeeting | null>(null);
    const [boardMembers, setBoardMembers] = useState<BoardMember[]>([]);
    const [tasks, setTasks] = useState<Task[]>([]);
    
    // Add Attendee State
    const [selectedUserIdToAdd, setSelectedUserIdToAdd] = useState('');

    // Member Management State
    const [newBoardMember, setNewBoardMember] = useState<{userId: string, role: string, quote: string, image: string}>({ 
        userId: '', role: '', quote: '', image: '' 
    });
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Task Creation Modal State
    const [showTaskModal, setShowTaskModal] = useState(false);
    const [currentAgendaIndex, setCurrentAgendaIndex] = useState<number | null>(null);
    const [newTaskData, setNewTaskData] = useState({
        title: '',
        assignedToUserId: '',
        dueDate: '',
        priority: 'MEDIUM' as 'LOW' | 'MEDIUM' | 'HIGH'
    });

    // Preview / Export State
    const [showPreview, setShowPreview] = useState(false);

    useEffect(() => {
        const qMeetings = query(collection(db, 'board_meetings'), orderBy('date', 'desc'));
        const unsubMeetings = onSnapshot(qMeetings, (snap) => {
            setMeetings(snap.docs.map(d => ({ id: d.id, ...d.data() } as BoardMeeting)));
        });

        const qMembers = query(collection(db, 'board_members'));
        const unsubMembers = onSnapshot(qMembers, (snap) => {
            setBoardMembers(snap.docs.map(d => ({ id: d.id, ...d.data() } as BoardMember)));
        });

        const qTasks = query(collection(db, 'tasks'));
        const unsubTasks = onSnapshot(qTasks, (snap) => {
            setTasks(snap.docs.map(d => ({ id: d.id, ...d.data() } as Task)));
        });

        return () => { unsubMeetings(); unsubMembers(); unsubTasks(); };
    }, []);

    // --- PROTOCOL ACTIONS ---

    const createMeeting = async () => {
        // Prepare attendees based on current board members
        const currentAttendees: ProtocolAttendee[] = boardMembers.map(bm => {
            const user = users.find(u => u.id === bm.userId);
            return {
                userId: bm.userId,
                name: user?.displayName || 'Unknown',
                role: bm.role,
                present: false
            };
        });

        const newMeeting = {
            title: "Mbledhja e Kryesisë",
            date: new Date().toISOString().split('T')[0],
            status: "PLANNED",
            agendaItems: [],
            attendees: currentAttendees
        };

        const docRef = await addDoc(collection(db, 'board_meetings'), newMeeting);
        setSelectedMeeting({ id: docRef.id, ...newMeeting } as BoardMeeting);
    };

    const saveProtocol = async () => {
        if (!selectedMeeting) return;
        await updateDoc(doc(db, 'board_meetings', selectedMeeting.id), selectedMeeting as any);
        showAlert({ type: 'success', message: 'Protokolli u ruajt.' });
    };

    const deleteMeeting = async (id: string) => {
        if (await showConfirm({ title: "Fshij Protokollin", message: "A jeni i sigurt?", type: 'danger' })) {
            await deleteDoc(doc(db, 'board_meetings', id));
            if (selectedMeeting?.id === id) setSelectedMeeting(null);
        }
    };

    const updateAttendee = (index: number, present: boolean) => {
        if (!selectedMeeting) return;
        const updated = [...selectedMeeting.attendees];
        updated[index].present = present;
        setSelectedMeeting({ ...selectedMeeting, attendees: updated });
    };

    const handleAddAttendee = () => {
        if (!selectedMeeting || !selectedUserIdToAdd) return;
        
        // Find user details
        const userToAdd = users.find(u => u.id === selectedUserIdToAdd);
        if (!userToAdd) return;

        // Check if already in list
        if (selectedMeeting.attendees.some(a => a.userId === userToAdd.id)) {
            showAlert({ type: 'info', message: 'Ky person është tashmë në listë.' });
            return;
        }

        // Auto-detect role if user is a board member
        const boardMemberInfo = boardMembers.find(bm => bm.userId === userToAdd.id);
        const role = boardMemberInfo ? boardMemberInfo.role : 'Mysafir';

        const newAttendee: ProtocolAttendee = {
            userId: userToAdd.id,
            name: userToAdd.displayName || 'Unknown',
            role: role,
            present: true
        };

        setSelectedMeeting({
            ...selectedMeeting,
            attendees: [...selectedMeeting.attendees, newAttendee]
        });
        setSelectedUserIdToAdd('');
    };

    const removeAttendee = (index: number) => {
        if (!selectedMeeting) return;
        const updated = [...selectedMeeting.attendees];
        updated.splice(index, 1);
        setSelectedMeeting({ ...selectedMeeting, attendees: updated });
    };

    const addAgendaItem = () => {
        if (!selectedMeeting) return;
        const newItem: ProtocolAgendaItem = {
            id: Math.random().toString(36).substr(2, 9),
            title: '',
            responsible: '',
            dueDate: '',
            content: '',
            linkedTaskIds: []
        };
        setSelectedMeeting({
            ...selectedMeeting,
            agendaItems: [...(selectedMeeting.agendaItems || []), newItem]
        });
    };

    const updateAgendaItem = (index: number, field: keyof ProtocolAgendaItem, value: string) => {
        if (!selectedMeeting) return;
        const updated = [...selectedMeeting.agendaItems];
        updated[index] = { ...updated[index], [field]: value };
        setSelectedMeeting({ ...selectedMeeting, agendaItems: updated });
    };

    const removeAgendaItem = (index: number) => {
        if (!selectedMeeting) return;
        const updated = [...selectedMeeting.agendaItems];
        updated.splice(index, 1);
        setSelectedMeeting({ ...selectedMeeting, agendaItems: updated });
    };

    // --- TASK INTEGRATION ACTIONS ---

    const openTaskModal = (agendaIndex: number) => {
        const item = selectedMeeting?.agendaItems[agendaIndex];
        if (!item) return;
        
        setCurrentAgendaIndex(agendaIndex);
        setNewTaskData({
            title: item.title || '',
            assignedToUserId: '',
            dueDate: item.dueDate || '',
            priority: 'MEDIUM'
        });
        setShowTaskModal(true);
    };

    const handleCreateTask = async () => {
        if (currentAgendaIndex === null || !selectedMeeting) return;
        if (!newTaskData.title || !newTaskData.assignedToUserId) {
            showAlert({ type: 'error', message: "Ju lutem plotësoni titullin dhe personin përgjegjës." });
            return;
        }

        const assignee = users.find(u => u.id === newTaskData.assignedToUserId);
        
        // 1. Create Task in DB
        const taskDoc = await addDoc(collection(db, 'tasks'), {
            title: newTaskData.title,
            description: `Generated from meeting: ${selectedMeeting.title} (${selectedMeeting.date})`,
            status: 'TODO',
            priority: newTaskData.priority,
            assignedToName: assignee?.displayName || 'Unknown',
            assignedTo: [newTaskData.assignedToUserId], // Array for future multi-assign
            dueDate: newTaskData.dueDate,
            createdBy: auth.currentUser?.uid,
            createdAt: serverTimestamp(),
            sourceMeetingId: selectedMeeting.id
        });

        // 2. Link Task ID to Agenda Item in Protocol
        const updatedAgendaItems = [...selectedMeeting.agendaItems];
        const currentItem = updatedAgendaItems[currentAgendaIndex];
        const currentTasks = currentItem.linkedTaskIds || [];
        
        updatedAgendaItems[currentAgendaIndex] = {
            ...currentItem,
            linkedTaskIds: [...currentTasks, taskDoc.id]
        };

        const updatedMeeting = { ...selectedMeeting, agendaItems: updatedAgendaItems };
        setSelectedMeeting(updatedMeeting);
        
        // Auto-save protocol to persist the link
        await updateDoc(doc(db, 'board_meetings', selectedMeeting.id), updatedMeeting as any);

        setShowTaskModal(false);
        showAlert({ type: 'success', message: "Detyra u krijua me sukses!" });
    };

    // --- MEMBER MANAGEMENT ACTIONS ---

    const handleBoardImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        try {
            const storageRef = ref(storage, `board/${Date.now()}_${file.name}`);
            const snapshot = await uploadBytes(storageRef, file);
            const url = await getDownloadURL(snapshot.ref);
            setNewBoardMember(prev => ({ ...prev, image: url }));
        } catch (err) { console.error(err); }
    };

    const handleAddBoardMember = async () => {
        if (!newBoardMember.userId || !newBoardMember.role) return;
        
        // 1. Add to board_members list
        await addDoc(collection(db, 'board_members'), {
            ...newBoardMember,
            createdAt: serverTimestamp()
        });

        // 2. Update actual User Role to 'BOARD'
        await updateDoc(doc(db, 'users', newBoardMember.userId), {
            role: 'BOARD'
        });

        setNewBoardMember({ userId: '', role: '', quote: '', image: '' });
        showAlert({ type: 'success', message: 'Anëtari u shtua dhe u përditësua roli.' });
    };

    const handleDeleteBoardMember = async (id: string) => {
        if (await showConfirm({ title: "Fshij Anëtarin", message: "A jeni i sigurt?", type: 'danger' })) {
            const memberToDelete = boardMembers.find(bm => bm.id === id);
            
            await deleteDoc(doc(db, 'board_members', id));

            // Revert Role to MEMBER if they exist in users
            if (memberToDelete?.userId) {
                await updateDoc(doc(db, 'users', memberToDelete.userId), {
                    role: 'MEMBER'
                });
            }
            showAlert({ type: 'success', message: 'Anëtari u fshi dhe roli u kthye në Member.' });
        }
    };

    const handleSyncRoles = async () => {
        let count = 0;
        for (const bm of boardMembers) {
            const user = users.find(u => u.id === bm.userId);
            if (user && user.role !== 'BOARD') {
                await updateDoc(doc(db, 'users', user.id), { role: 'BOARD' });
                count++;
            }
        }
        showAlert({ type: 'success', message: `${count} përdorues u sinkronizuan në rolin 'BOARD'.` });
    };

    // --- PREVIEW & EXPORT ACTIONS ---
    const handleShare = async () => {
        if (!selectedMeeting) return;
        const text = `Protokoll: ${selectedMeeting.title}\nData: ${selectedMeeting.date}\n\n${selectedMeeting.agendaItems.map((item, i) => `${i+1}. ${item.title}`).join('\n')}`;
        
        if (navigator.share) {
            try {
                await navigator.share({
                    title: selectedMeeting.title,
                    text: text,
                });
            } catch (err) {
                console.log('Error sharing:', err);
            }
        } else {
            navigator.clipboard.writeText(text);
            showAlert({ type: 'success', message: 'Përmbledhja u kopjua në clipboard!' });
        }
    };

    const handlePrint = () => {
        window.print();
    };

    return (
        <div className="bg-white rounded-[2.5rem] border border-stone-100 shadow-sm overflow-hidden h-[800px] flex flex-col relative">
            {/* Header / Tabs */}
            <div className="flex border-b border-stone-100 p-2 gap-2 bg-stone-50">
                <button 
                    onClick={() => setActiveTab('PROTOCOLS')} 
                    className={`flex-1 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all ${activeTab === 'PROTOCOLS' ? 'bg-white text-primary shadow-sm' : 'text-stone-400 hover:text-stone-600'}`}
                >
                    <FileText size={16} /> Protokolle & Mbledhje
                </button>
                <button 
                    onClick={() => setActiveTab('MEMBERS')} 
                    className={`flex-1 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 transition-all ${activeTab === 'MEMBERS' ? 'bg-white text-primary shadow-sm' : 'text-stone-400 hover:text-stone-600'}`}
                >
                    <Users size={16} /> Anëtarët e Kryesisë
                </button>
            </div>

            {/* Content Area */}
            <div className="flex-1 overflow-hidden">
                
                {activeTab === 'MEMBERS' && (
                    <div className="p-8 h-full overflow-y-auto custom-scrollbar">
                        <div className="max-w-4xl mx-auto space-y-8">
                            
                            <div className="flex justify-end">
                                <button onClick={handleSyncRoles} className="text-xs font-bold text-stone-400 hover:text-primary flex items-center gap-2">
                                    <RefreshCw size={12}/> Sinkronizo Rolet
                                </button>
                            </div>

                            <div className="bg-stone-50 p-6 rounded-3xl border border-stone-200">
                                <h4 className="font-bold text-stone-900 mb-6 flex items-center gap-2"><Plus size={18} /> Shto Anëtar të Ri</h4>
                                <div className="flex gap-6 items-start">
                                    <div 
                                        onClick={() => fileInputRef.current?.click()}
                                        className="w-24 h-24 bg-white border-2 border-dashed border-stone-200 rounded-2xl flex items-center justify-center cursor-pointer hover:border-primary overflow-hidden relative shrink-0"
                                    >
                                        {newBoardMember.image ? <img src={newBoardMember.image} className="w-full h-full object-cover"/> : <Upload size={20} className="text-stone-300"/>}
                                        <input type="file" ref={fileInputRef} hidden accept="image/*" onChange={handleBoardImageUpload} />
                                    </div>
                                    <div className="flex-1 space-y-4">
                                        <div className="grid grid-cols-2 gap-4">
                                            <select 
                                                value={newBoardMember.userId} 
                                                onChange={e => setNewBoardMember({...newBoardMember, userId: e.target.value})} 
                                                className="w-full p-3 bg-white rounded-xl text-sm border border-stone-200 outline-none"
                                            >
                                                <option value="">Zgjidh Anëtarin...</option>
                                                {users.map(u => <option key={u.id} value={u.id}>{u.displayName} ({u.email})</option>)}
                                            </select>
                                            <input 
                                                placeholder="Funksioni (psh. Kryetar)" 
                                                value={newBoardMember.role} 
                                                onChange={e => setNewBoardMember({...newBoardMember, role: e.target.value})} 
                                                className="w-full p-3 bg-white rounded-xl text-sm border border-stone-200 outline-none" 
                                            />
                                        </div>
                                        <textarea 
                                            placeholder="Citat ose Përshkrim..." 
                                            value={newBoardMember.quote} 
                                            onChange={e => setNewBoardMember({...newBoardMember, quote: e.target.value})} 
                                            className="w-full p-3 bg-white rounded-xl text-sm border border-stone-200 outline-none h-20" 
                                        />
                                        <button onClick={handleAddBoardMember} disabled={!newBoardMember.userId} className="px-6 py-3 bg-stone-900 text-white rounded-xl text-sm font-bold disabled:opacity-50 hover:bg-black transition-all">
                                            Ruaj Anëtarin
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                {boardMembers.map(bm => {
                                    const u = users.find(user => user.id === bm.userId);
                                    return (
                                        <div key={bm.id} className="flex items-center gap-4 p-4 bg-white border border-stone-100 rounded-2xl shadow-sm group hover:shadow-md transition-all">
                                            <img src={bm.image || u?.photoFileName} className="w-12 h-12 rounded-xl object-cover bg-stone-100"/>
                                            <div className="flex-1">
                                                <p className="font-bold text-stone-900">{u?.displayName}</p>
                                                <p className="text-xs text-primary font-bold uppercase tracking-wide">{bm.role}</p>
                                            </div>
                                            <button onClick={() => handleDeleteBoardMember(bm.id)} className="p-2 bg-stone-50 text-stone-400 hover:text-red-500 rounded-lg opacity-0 group-hover:opacity-100 transition-all"><Trash2 size={16}/></button>
                                        </div>
                                    )
                                })}
                            </div>
                        </div>
                    </div>
                )}

                {activeTab === 'PROTOCOLS' && (
                    <div className="grid grid-cols-12 h-full">
                        {/* Sidebar: Archive */}
                        <div className="col-span-3 border-r border-stone-100 bg-stone-50/50 p-4 overflow-y-auto">
                            <button onClick={createMeeting} className="w-full py-3 bg-stone-900 text-white rounded-xl font-bold text-sm mb-6 flex items-center justify-center gap-2 hover:bg-black shadow-lg">
                                <Plus size={16} /> Protokoll i Ri
                            </button>
                            <h4 className="text-xs font-bold text-stone-400 uppercase tracking-widest mb-3 px-2">Arkiva</h4>
                            <div className="space-y-2">
                                {meetings.map(m => (
                                    <div 
                                        key={m.id} 
                                        onClick={() => setSelectedMeeting(m)}
                                        className={`p-4 rounded-xl cursor-pointer border transition-all group ${selectedMeeting?.id === m.id ? 'bg-white border-primary shadow-md' : 'bg-transparent border-transparent hover:bg-white hover:border-stone-200'}`}
                                    >
                                        <div className="flex justify-between items-start mb-1">
                                            <span className="font-bold text-stone-800 text-sm line-clamp-1">{m.title}</span>
                                            <button onClick={(e) => { e.stopPropagation(); deleteMeeting(m.id); }} className="text-stone-300 hover:text-red-500 opacity-0 group-hover:opacity-100"><Trash2 size={12}/></button>
                                        </div>
                                        <span className="text-xs text-stone-500 flex items-center gap-1"><Calendar size={10}/> {m.date}</span>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Main Editor */}
                        <div className="col-span-9 p-8 overflow-y-auto custom-scrollbar bg-[#faf9f6]">
                            {selectedMeeting ? (
                                <div className="max-w-4xl mx-auto space-y-8 pb-20">
                                    {/* Header Info */}
                                    <div className="flex justify-between items-start">
                                        <div className="space-y-2 flex-1 max-w-lg">
                                            <input 
                                                value={selectedMeeting.title} 
                                                onChange={e => setSelectedMeeting({...selectedMeeting, title: e.target.value})} 
                                                className="text-3xl font-display font-bold bg-transparent outline-none w-full placeholder-stone-300" 
                                                placeholder="Titulli i Mbledhjes"
                                            />
                                            <div className="flex items-center gap-2 bg-white px-3 py-1.5 rounded-lg border border-stone-200 w-fit">
                                                <Calendar size={14} className="text-stone-400" />
                                                <input 
                                                    type="date" 
                                                    value={selectedMeeting.date} 
                                                    onChange={e => setSelectedMeeting({...selectedMeeting, date: e.target.value})} 
                                                    className="bg-transparent outline-none text-sm font-medium text-stone-600"
                                                />
                                            </div>
                                        </div>
                                        <div className="flex gap-2">
                                            <button onClick={() => setShowPreview(true)} className="bg-white border border-stone-200 text-stone-600 px-4 py-2.5 rounded-xl font-bold flex items-center gap-2 hover:bg-stone-50 transition-all">
                                                <Eye size={18} /> Preview / PDF
                                            </button>
                                            <button onClick={saveProtocol} className="bg-primary text-white px-6 py-2.5 rounded-xl font-bold flex items-center gap-2 shadow-lg shadow-rose-200 hover:scale-105 transition-all">
                                                <Save size={18} /> Ruaj
                                            </button>
                                        </div>
                                    </div>

                                    {/* 1. Pjesëmarrësit (Attendees) */}
                                    <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                                        <div className="flex justify-between items-center mb-4">
                                            <h4 className="font-bold text-stone-900 flex items-center gap-2"><Users size={18} className="text-primary" /> Pjesëmarrësit</h4>
                                            
                                            {/* Manual Add Selection */}
                                            <div className="flex items-center gap-2">
                                                <select 
                                                    value={selectedUserIdToAdd}
                                                    onChange={(e) => setSelectedUserIdToAdd(e.target.value)}
                                                    className="p-2 bg-stone-50 border border-stone-200 rounded-lg text-xs font-medium outline-none w-48"
                                                >
                                                    <option value="">Shto Pjesëmarrës...</option>
                                                    <optgroup label="Anëtarët e Kryesisë">
                                                        {users.filter(u => boardMembers.some(bm => bm.userId === u.id)).map(u => {
                                                             const role = boardMembers.find(bm => bm.userId === u.id)?.role;
                                                             return <option key={u.id} value={u.id}>{u.displayName} ({role})</option>
                                                        })}
                                                    </optgroup>
                                                    <optgroup label="Mysafirë & Të Tjerë">
                                                        {users.filter(u => !boardMembers.some(bm => bm.userId === u.id)).map(u => (
                                                            <option key={u.id} value={u.id}>{u.displayName}</option>
                                                        ))}
                                                    </optgroup>
                                                </select>
                                                <button onClick={handleAddAttendee} disabled={!selectedUserIdToAdd} className="p-2 bg-stone-900 text-white rounded-lg hover:bg-black disabled:opacity-50">
                                                    <Plus size={14} />
                                                </button>
                                            </div>
                                        </div>

                                        <div className="overflow-x-auto">
                                            <table className="w-full text-left text-sm">
                                                <thead className="bg-stone-50 text-stone-500 font-bold uppercase text-[10px] tracking-widest border-b border-stone-100">
                                                    <tr>
                                                        <th className="px-4 py-3 rounded-tl-xl">Emri</th>
                                                        <th className="px-4 py-3">Funksioni</th>
                                                        <th className="px-4 py-3 text-center">Të pranishëm</th>
                                                        <th className="px-4 py-3 rounded-tr-xl w-10"></th>
                                                    </tr>
                                                </thead>
                                                <tbody className="divide-y divide-stone-50">
                                                    {selectedMeeting.attendees?.map((att, idx) => (
                                                        <tr key={`${att.userId}_${idx}`} className="hover:bg-stone-50 group">
                                                            <td className="px-4 py-3 font-bold text-stone-800">{att.name}</td>
                                                            <td className="px-4 py-3 text-stone-500">{att.role}</td>
                                                            <td className="px-4 py-3 text-center">
                                                                <button 
                                                                    onClick={() => updateAttendee(idx, !att.present)}
                                                                    className={`px-3 py-1 rounded-full text-xs font-bold transition-all ${att.present ? 'bg-green-100 text-green-700' : 'bg-red-50 text-red-400'}`}
                                                                >
                                                                    {att.present ? 'Po' : 'Jo'}
                                                                </button>
                                                            </td>
                                                            <td className="px-4 py-3 text-center">
                                                                <button onClick={() => removeAttendee(idx)} className="text-stone-300 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">
                                                                    <X size={14} />
                                                                </button>
                                                            </td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>

                                    {/* 2. Rendi i Ditës (Agenda Overview) */}
                                    <div className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm">
                                        <h4 className="font-bold text-stone-900 mb-4 flex items-center gap-2"><List size={18} className="text-primary" /> Rendi i Ditës</h4>
                                        <div className="space-y-2 mb-4">
                                            {selectedMeeting.agendaItems?.map((item, idx) => (
                                                <div key={item.id} className="flex items-center gap-3 p-2 bg-stone-50 rounded-xl border border-stone-100">
                                                    <div className="w-6 h-6 bg-white rounded-full flex items-center justify-center font-bold text-xs text-stone-400 border border-stone-200">{idx + 1}</div>
                                                    <input 
                                                        value={item.title}
                                                        onChange={(e) => updateAgendaItem(idx, 'title', e.target.value)}
                                                        placeholder="Pika e rendit të ditës..."
                                                        className="flex-1 bg-transparent outline-none font-medium text-stone-800"
                                                    />
                                                    <input 
                                                        value={item.responsible}
                                                        onChange={(e) => updateAgendaItem(idx, 'responsible', e.target.value)}
                                                        placeholder="Përgjegjësi"
                                                        className="w-32 bg-white px-2 py-1 rounded-lg border border-stone-200 text-xs outline-none"
                                                    />
                                                    <button onClick={() => removeAgendaItem(idx)} className="text-stone-300 hover:text-red-500"><X size={16}/></button>
                                                </div>
                                            ))}
                                        </div>
                                        <button onClick={addAgendaItem} className="text-xs font-bold text-stone-400 hover:text-primary flex items-center gap-1">
                                            <Plus size={14}/> Shto pikë
                                        </button>
                                    </div>

                                    {/* 3. Detailed Topics (WYSIWYG) */}
                                    <div className="space-y-6">
                                        <h4 className="font-bold text-stone-900 text-lg border-b border-stone-200 pb-2">Detajet e Temave</h4>
                                        {selectedMeeting.agendaItems?.length === 0 && <p className="text-stone-400 italic text-sm">Shtoni pika në rendin e ditës për të shkruar detajet.</p>}
                                        
                                        {selectedMeeting.agendaItems?.map((item, idx) => (
                                            <div key={item.id} className="bg-white p-6 rounded-3xl border border-stone-100 shadow-sm relative">
                                                <div className="flex justify-between items-center mb-4">
                                                    <h5 className="font-bold text-lg text-primary flex items-center gap-2">
                                                        <span className="bg-rose-50 px-2 py-0.5 rounded text-sm">{idx + 1}</span> 
                                                        {item.title || 'Temë pa titull'}
                                                    </h5>
                                                    <div className="flex gap-2">
                                                        <div className="flex items-center gap-1 bg-stone-50 px-3 py-1.5 rounded-lg border border-stone-100">
                                                            <User size={12} className="text-stone-400"/>
                                                            <span className="text-xs font-bold text-stone-600">{item.responsible || 'Përgjegjësi'}</span>
                                                        </div>
                                                        <div className="flex items-center gap-1 bg-stone-50 px-3 py-1.5 rounded-lg border border-stone-100">
                                                            <Calendar size={12} className="text-stone-400"/>
                                                            <input 
                                                                type="date"
                                                                value={item.dueDate}
                                                                onChange={(e) => updateAgendaItem(idx, 'dueDate', e.target.value)}
                                                                className="bg-transparent outline-none text-xs font-bold text-stone-600 w-24"
                                                            />
                                                        </div>
                                                    </div>
                                                </div>
                                                
                                                <RichTextEditor 
                                                    value={item.content} 
                                                    onChange={(val) => updateAgendaItem(idx, 'content', val)} 
                                                    placeholder={`Shkruaj detajet për "${item.title || 'këtë temë'}"...`}
                                                />

                                                {/* --- LINKED TASKS SECTION --- */}
                                                <div className="mt-6 pt-4 border-t border-stone-100">
                                                    <div className="flex justify-between items-center mb-3">
                                                        <h6 className="text-[10px] font-bold text-stone-400 uppercase tracking-widest flex items-center gap-1"><CheckSquare size={12}/> Veprime / Detyra</h6>
                                                        <button 
                                                            onClick={() => openTaskModal(idx)}
                                                            className="text-[10px] bg-stone-50 hover:bg-stone-100 text-primary font-bold px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1"
                                                        >
                                                            <Plus size={12}/> Krijo Detyrë
                                                        </button>
                                                    </div>
                                                    
                                                    {item.linkedTaskIds && item.linkedTaskIds.length > 0 ? (
                                                        <div className="space-y-2">
                                                            {item.linkedTaskIds.map(taskId => {
                                                                const task = tasks.find(t => t.id === taskId);
                                                                if (!task) return null;
                                                                return (
                                                                    <div key={taskId} className="flex items-center justify-between p-2 bg-stone-50 rounded-lg border border-stone-100 text-xs">
                                                                        <div className="flex items-center gap-2">
                                                                            <span className={`w-2 h-2 rounded-full ${task.status === 'DONE' ? 'bg-green-500' : task.status === 'IN_PROGRESS' ? 'bg-blue-500' : 'bg-stone-300'}`} />
                                                                            <span className="font-bold text-stone-700">{task.title}</span>
                                                                            <span className="text-stone-400">({task.assignedToName})</span>
                                                                        </div>
                                                                        <span className={`px-2 py-0.5 rounded text-[9px] font-bold ${task.status === 'DONE' ? 'bg-green-100 text-green-700' : 'bg-stone-200 text-stone-500'}`}>{task.status}</span>
                                                                    </div>
                                                                )
                                                            })}
                                                        </div>
                                                    ) : (
                                                        <p className="text-xs text-stone-300 italic">Asnjë detyrë e krijuar për këtë pikë.</p>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>

                                </div>
                            ) : (
                                <div className="h-full flex flex-col items-center justify-center text-stone-400 opacity-60">
                                    <FileText size={64} className="mb-4 stroke-1"/>
                                    <p>Zgjidhni një protokoll ose krijoni të ri.</p>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* PREVIEW / PDF MODAL */}
            <AnimatePresence>
                {showPreview && selectedMeeting && (
                    <div className="fixed inset-0 z-[400] bg-stone-900/80 backdrop-blur-md flex items-center justify-center p-4">
                        <motion.div initial={{opacity:0, scale:0.95}} animate={{opacity:1, scale:1}} exit={{opacity:0, scale:0.95}} className="bg-white h-[90vh] w-full max-w-4xl rounded-2xl flex flex-col overflow-hidden">
                            {/* Toolbar */}
                            <div className="bg-stone-50 border-b border-stone-200 p-4 flex justify-between items-center shrink-0">
                                <h3 className="font-bold text-stone-800">Protokoll Preview</h3>
                                <div className="flex gap-2">
                                    <button onClick={handleShare} className="flex items-center gap-2 px-4 py-2 bg-white border border-stone-200 rounded-lg text-sm font-bold text-stone-600 hover:text-primary transition-colors">
                                        <Share2 size={16}/> Share
                                    </button>
                                    <button onClick={handlePrint} className="flex items-center gap-2 px-4 py-2 bg-stone-900 text-white rounded-lg text-sm font-bold hover:bg-black transition-colors">
                                        <Printer size={16}/> Download / Print PDF
                                    </button>
                                    <button onClick={() => setShowPreview(false)} className="p-2 hover:bg-stone-200 rounded-lg text-stone-500">
                                        <X size={20}/>
                                    </button>
                                </div>
                            </div>
                            
                            {/* Printable Content Area */}
                            <div className="flex-1 overflow-y-auto bg-stone-200 p-8 flex justify-center">
                                <div id="protocol-preview" className="bg-white shadow-xl w-[210mm] min-h-[297mm] p-[20mm] text-stone-900 printable-area">
                                    {/* Print Styles */}
                                    <style>{`
                                        @media print {
                                            body * { visibility: hidden; }
                                            .printable-area, .printable-area * { visibility: visible; }
                                            .printable-area { position: absolute; left: 0; top: 0; width: 100%; margin: 0; padding: 20mm; box-shadow: none; }
                                            @page { size: A4; margin: 0; }
                                        }
                                    `}</style>

                                    <div className="border-b-2 border-stone-900 pb-4 mb-8 flex justify-between items-end">
                                        <div>
                                            <h1 className="text-3xl font-display font-bold italic mb-2">Protokoll</h1>
                                            <h2 className="text-xl font-bold">{selectedMeeting.title}</h2>
                                        </div>
                                        <div className="text-right text-sm">
                                            <p className="font-bold">Shoqata Koretini</p>
                                            <p className="text-stone-500">{new Date(selectedMeeting.date).toLocaleDateString('sq-AL', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
                                        </div>
                                    </div>

                                    {/* Attendees */}
                                    <div className="mb-8">
                                        <h3 className="text-sm font-bold uppercase tracking-widest border-b border-stone-200 pb-2 mb-4 text-stone-500">Pjesëmarrësit</h3>
                                        <div className="grid grid-cols-2 gap-x-8 gap-y-2 text-sm">
                                            {selectedMeeting.attendees.map((att, i) => (
                                                <div key={i} className="flex justify-between border-b border-stone-100 py-1">
                                                    <span>{att.name} <span className="text-stone-400 text-xs">({att.role})</span></span>
                                                    <span className={att.present ? 'text-stone-900 font-bold' : 'text-stone-400 italic'}>{att.present ? 'Prezent' : 'Mungon'}</span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Agenda */}
                                    <div className="space-y-8">
                                        <h3 className="text-sm font-bold uppercase tracking-widest border-b border-stone-200 pb-2 mb-4 text-stone-500">Rendi i Ditës & Diskutimet</h3>
                                        {selectedMeeting.agendaItems.map((item, i) => (
                                            <div key={i} className="mb-6 break-inside-avoid">
                                                <div className="flex items-baseline gap-3 mb-2">
                                                    <span className="text-lg font-bold text-stone-900">{i+1}.</span>
                                                    <h4 className="text-lg font-bold text-stone-900">{item.title}</h4>
                                                </div>
                                                <div className="pl-7">
                                                    <div className="flex gap-4 text-xs text-stone-500 mb-3 font-mono">
                                                        <span>Përgjegjës: {item.responsible}</span>
                                                        {item.dueDate && <span>Afati: {item.dueDate}</span>}
                                                    </div>
                                                    <div 
                                                        className="prose prose-stone prose-sm text-justify leading-relaxed max-w-none"
                                                        dangerouslySetInnerHTML={{ __html: item.content }}
                                                    />
                                                </div>
                                            </div>
                                        ))}
                                    </div>

                                    {/* Footer / Signatures */}
                                    <div className="mt-20 pt-8 border-t border-stone-200 flex justify-between break-inside-avoid">
                                        <div className="w-40 border-t border-stone-900 pt-2 text-xs text-center">
                                            <p className="font-bold">Kryesuesi</p>
                                        </div>
                                        <div className="w-40 border-t border-stone-900 pt-2 text-xs text-center">
                                            <p className="font-bold">Protokollisti</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* TASK CREATION MODAL */}
            <AnimatePresence>
                {showTaskModal && (
                    <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-stone-900/60 backdrop-blur-sm">
                        <motion.div 
                            initial={{ scale: 0.95, opacity: 0 }} 
                            animate={{ scale: 1, opacity: 1 }} 
                            exit={{ scale: 0.95, opacity: 0 }}
                            className="bg-white w-full max-w-md rounded-[2rem] p-8 shadow-2xl relative"
                        >
                            <button onClick={() => setShowTaskModal(false)} className="absolute top-6 right-6 p-2 text-stone-400 hover:text-stone-900"><X size={20}/></button>
                            
                            <h3 className="text-xl font-bold mb-6 flex items-center gap-2"><CheckSquare className="text-primary"/> Krijo Detyrë</h3>
                            
                            <div className="space-y-4">
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Titulli i Detyrës</label>
                                    <input 
                                        value={newTaskData.title} 
                                        onChange={e => setNewTaskData({...newTaskData, title: e.target.value})} 
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl font-medium outline-none focus:border-primary/50"
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Personi Përgjegjës</label>
                                    <select 
                                        value={newTaskData.assignedToUserId} 
                                        onChange={e => setNewTaskData({...newTaskData, assignedToUserId: e.target.value})} 
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl font-medium outline-none focus:border-primary/50"
                                    >
                                        <option value="">Zgjidh...</option>
                                        {users.map(u => (
                                            <option key={u.id} value={u.id}>{u.displayName}</option>
                                        ))}
                                    </select>
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Afati (Due Date)</label>
                                    <input 
                                        type="date"
                                        value={newTaskData.dueDate} 
                                        onChange={e => setNewTaskData({...newTaskData, dueDate: e.target.value})} 
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl font-medium outline-none focus:border-primary/50"
                                    />
                                </div>
                                <div>
                                    <label className="text-[10px] font-bold text-stone-400 uppercase tracking-widest block mb-1">Prioriteti</label>
                                    <select 
                                        value={newTaskData.priority} 
                                        onChange={e => setNewTaskData({...newTaskData, priority: e.target.value as any})} 
                                        className="w-full p-3 bg-stone-50 border border-stone-200 rounded-xl font-medium outline-none focus:border-primary/50"
                                    >
                                        <option value="LOW">Low</option>
                                        <option value="MEDIUM">Medium</option>
                                        <option value="HIGH">High</option>
                                    </select>
                                </div>
                            </div>

                            <div className="flex gap-3 mt-8">
                                <button onClick={() => setShowTaskModal(false)} className="flex-1 py-3 bg-stone-100 rounded-xl font-bold text-stone-500 hover:bg-stone-200 transition-colors">Anulo</button>
                                <button onClick={handleCreateTask} className="flex-1 py-3 bg-stone-900 text-white rounded-xl font-bold hover:bg-black transition-colors shadow-lg">Krijo</button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default AdminBoard;
