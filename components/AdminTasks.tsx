import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Clock, CheckCircle2, MoreHorizontal, User, Trash2, Loader2 } from 'lucide-react';
import { db, auth } from '../services/firebase';
import { collection, query, orderBy, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { Task, UserProfile } from '../types';
import { useFeedback } from '../context/FeedbackContext';

interface AdminTasksProps {
    users: UserProfile[];
}

interface TaskCardProps {
    task: Task;
    onUpdateStatus: (task: Task, status: 'TODO' | 'IN_PROGRESS' | 'DONE') => Promise<void>;
    onAssignUser: (task: Task) => Promise<void>;
    onDeleteTask: (id: string) => Promise<void>;
}

const TaskCard: React.FC<TaskCardProps> = ({ task, onUpdateStatus, onAssignUser, onDeleteTask }) => (
    <motion.div layoutId={task.id} className="bg-white p-4 rounded-xl border border-stone-100 shadow-sm mb-3 group hover:shadow-md transition-all">
        <div className="flex justify-between items-start mb-2">
            <span className={`text-[9px] font-bold px-2 py-0.5 rounded uppercase ${task.priority === 'HIGH' ? 'bg-red-100 text-red-600' : 'bg-stone-100 text-stone-500'}`}>{task.priority}</span>
            <button onClick={() => onDeleteTask(task.id)} className="opacity-0 group-hover:opacity-100 text-stone-300 hover:text-red-500"><Trash2 size={14}/></button>
        </div>
        <p className="text-sm font-medium text-stone-800 mb-3">{task.title}</p>
        <div className="flex justify-between items-center pt-2 border-t border-stone-50">
            <div 
                onClick={() => onAssignUser(task)}
                className="flex items-center gap-1 text-xs text-stone-400 hover:text-primary cursor-pointer"
            >
                <User size={12}/> {task.assignedToName || 'Unassigned'}
            </div>
            <div className="flex gap-1">
                {task.status !== 'TODO' && <button onClick={() => onUpdateStatus(task, 'TODO')} className="w-2 h-2 rounded-full bg-stone-300 hover:bg-stone-400" title="Move to Todo" />}
                {task.status !== 'IN_PROGRESS' && <button onClick={() => onUpdateStatus(task, 'IN_PROGRESS')} className="w-2 h-2 rounded-full bg-blue-300 hover:bg-blue-400" title="Move to In Progress" />}
                {task.status !== 'DONE' && <button onClick={() => onUpdateStatus(task, 'DONE')} className="w-2 h-2 rounded-full bg-green-300 hover:bg-green-400" title="Move to Done" />}
            </div>
        </div>
    </motion.div>
);

const AdminTasks: React.FC<AdminTasksProps> = ({ users }) => {
    const { showConfirm, showPrompt } = useFeedback();
    const [tasks, setTasks] = useState<Task[]>([]);
    const [newTaskTitle, setNewTaskTitle] = useState('');

    useEffect(() => {
        const q = query(collection(db, 'tasks'), orderBy('createdAt', 'desc'));
        const unsub = onSnapshot(q, (snap) => {
            setTasks(snap.docs.map(d => ({ id: d.id, ...d.data() } as Task)));
        });
        return () => unsub();
    }, []);

    const addTask = async () => {
        if (!newTaskTitle.trim()) return;
        await addDoc(collection(db, 'tasks'), {
            title: newTaskTitle,
            status: 'TODO',
            priority: 'MEDIUM',
            createdBy: auth.currentUser?.uid,
            createdAt: serverTimestamp()
        });
        setNewTaskTitle('');
    };

    const updateStatus = async (task: Task, status: 'TODO' | 'IN_PROGRESS' | 'DONE') => {
        await updateDoc(doc(db, 'tasks', task.id), { status });
    };

    const assignUser = async (task: Task) => {
        // Simplified assignment logic for now
        const name = await showPrompt({
            title: "Assign Task",
            message: "Enter name of assignee:",
            placeholder: "e.g. John"
        });
        if(name) {
            await updateDoc(doc(db, 'tasks', task.id), { assignedToName: name });
        }
    };

    const deleteTask = async (id: string) => {
        const confirm = await showConfirm({ title: "Delete Task", message: "Are you sure?", type: 'danger' });
        if (confirm) await deleteDoc(doc(db, 'tasks', id));
    };

    return (
        <div className="h-[600px] flex flex-col">
            <div className="mb-6 flex gap-4">
                <input 
                    value={newTaskTitle}
                    onChange={(e) => setNewTaskTitle(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && addTask()}
                    placeholder="New task..."
                    className="flex-1 p-3 bg-white border border-stone-200 rounded-xl outline-none"
                />
                <button onClick={addTask} className="bg-stone-900 text-white px-6 rounded-xl font-bold flex items-center gap-2"><Plus size={18}/> Add</button>
            </div>

            <div className="flex-1 overflow-x-auto">
                <div className="flex gap-6 h-full min-w-[800px]">
                    {/* TODO COL */}
                    <div className="flex-1 bg-stone-50 rounded-2xl p-4 flex flex-col">
                        <h4 className="font-bold text-stone-500 mb-4 flex items-center gap-2 text-sm uppercase tracking-widest"><Clock size={16}/> Todo ({tasks.filter(t => t.status === 'TODO').length})</h4>
                        <div className="flex-1 overflow-y-auto custom-scrollbar pr-2">
                            {tasks.filter(t => t.status === 'TODO').map(t => (
                                <TaskCard 
                                    key={t.id} 
                                    task={t} 
                                    onUpdateStatus={updateStatus} 
                                    onAssignUser={assignUser} 
                                    onDeleteTask={deleteTask} 
                                />
                            ))}
                        </div>
                    </div>

                    {/* IN PROGRESS COL */}
                    <div className="flex-1 bg-stone-50 rounded-2xl p-4 flex flex-col">
                        <h4 className="font-bold text-blue-500 mb-4 flex items-center gap-2 text-sm uppercase tracking-widest"><Loader2 size={16} className="animate-spin"/> In Progress ({tasks.filter(t => t.status === 'IN_PROGRESS').length})</h4>
                        <div className="flex-1 overflow-y-auto custom-scrollbar pr-2">
                            {tasks.filter(t => t.status === 'IN_PROGRESS').map(t => (
                                <TaskCard 
                                    key={t.id} 
                                    task={t} 
                                    onUpdateStatus={updateStatus} 
                                    onAssignUser={assignUser} 
                                    onDeleteTask={deleteTask} 
                                />
                            ))}
                        </div>
                    </div>

                    {/* DONE COL */}
                    <div className="flex-1 bg-stone-50 rounded-2xl p-4 flex flex-col">
                        <h4 className="font-bold text-green-500 mb-4 flex items-center gap-2 text-sm uppercase tracking-widest"><CheckCircle2 size={16}/> Done ({tasks.filter(t => t.status === 'DONE').length})</h4>
                        <div className="flex-1 overflow-y-auto custom-scrollbar pr-2">
                            {tasks.filter(t => t.status === 'DONE').map(t => (
                                <TaskCard 
                                    key={t.id} 
                                    task={t} 
                                    onUpdateStatus={updateStatus} 
                                    onAssignUser={assignUser} 
                                    onDeleteTask={deleteTask} 
                                />
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminTasks;