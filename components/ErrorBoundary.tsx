import React from 'react';
import { AlertTriangle, RotateCcw } from 'lucide-react';
import { useTranslation } from '../context/LanguageContext';

const Fallback: React.FC<{ onRetry: () => void }> = ({ onRetry }) => {
  const { t } = useTranslation();
  return (
    <div className="min-h-[60vh] flex items-center justify-center px-6 py-16">
      <div className="max-w-md text-center">
        <div className="mx-auto mb-5 flex h-12 w-12 items-center justify-center rounded-full bg-rose-50 text-primary">
          <AlertTriangle size={22} />
        </div>
        <h1 className="text-2xl font-serif text-stone-900 mb-2">{t('error.boundary.title')}</h1>
        <p className="text-stone-500 mb-6">{t('error.boundary.text')}</p>
        <button
          onClick={onRetry}
          className="inline-flex items-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-medium text-white hover:bg-rose-600 transition-colors"
        >
          <RotateCcw size={16} />
          {t('error.boundary.retry')}
        </button>
      </div>
    </div>
  );
};

interface Props { children: React.ReactNode }
interface State { hasError: boolean }

/**
 * Faengt Render-Fehler einzelner Seiten ab. Ohne diese Grenze hat ein einziger
 * Fehler (z. B. fehlendes WebGL auf der Ueber-uns-Seite) die komplette
 * Anwendung auf eine weisse Seite reduziert.
 */
export class ErrorBoundary extends React.Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[ErrorBoundary]', error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return <Fallback onRetry={() => this.setState({ hasError: false })} />;
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
