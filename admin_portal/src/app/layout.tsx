'use client';

import React, { useState } from 'react';
import './globals.css';
import Sidebar from '@/components/Sidebar';
import Header from '@/components/Header';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <html lang="en">
      <head>
        <title>Book & Bite — Admin & Merchant Operations</title>
        <meta name="description" content="Table reservation and restaurant onboarding dashboard" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body className="bg-slate-50 text-slate-900 antialiased font-sans">
        <div className="min-h-screen flex">
          {/* Main Sidebar */}
          <Sidebar 
            isOpen={sidebarOpen} 
            onClose={() => setSidebarOpen(false)} 
          />

          {/* Main Content Area */}
          <div className="flex-1 flex flex-col lg:pl-72 min-w-0 transition-all">
            <Header onToggleSidebar={() => setSidebarOpen(!sidebarOpen)} />
            <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
              {children}
            </main>
          </div>
        </div>
      </body>
    </html>
  );
}
