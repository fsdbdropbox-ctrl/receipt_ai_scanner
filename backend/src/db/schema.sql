-- AuditReady Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (OAuth-based)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    oauth_provider VARCHAR(50) NOT NULL, -- 'apple', 'google'
    oauth_id VARCHAR(255) NOT NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(oauth_provider, oauth_id)
);

-- Fiscal Profiles (User's tax context)
CREATE TABLE IF NOT EXISTS fiscal_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    country_code VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2 (ES, MX, DE, etc.)
    tax_id VARCHAR(50) NOT NULL, -- NIF, RFC, VAT ID, etc.
    tax_regime VARCHAR(50) NOT NULL, -- 'autonomo', 'empresa', 'simplificado', etc.
    activity_sector VARCHAR(100), -- Optional: sector description
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id) -- One profile per user
);

-- Documents (Scanned invoices/receipts)
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fiscal_profile_id UUID NOT NULL REFERENCES fiscal_profiles(id) ON DELETE CASCADE,
    
    -- Extracted data
    total DECIMAL(12, 2),
    tax DECIMAL(12, 2),
    vendor VARCHAR(255),
    invoice_date DATE,
    currency VARCHAR(3) DEFAULT 'EUR',
    category VARCHAR(50),
    
    -- Validation status
    validation_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'valid', 'invalid', 'quarantine', 'pending'
    validation_errors JSONB DEFAULT '[]'::jsonb, -- Array of error codes
    semantic_warnings JSONB DEFAULT '[]'::jsonb, -- Array of warnings
    
    -- File metadata
    file_url TEXT NOT NULL, -- S3/R2 URL
    file_hash VARCHAR(64) NOT NULL, -- SHA-256 for deduplication
    mime_type VARCHAR(50),
    
    -- Processing metadata
    scanned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    archived_at TIMESTAMP WITH TIME ZONE,
    confidence DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Validation flags (detailed validation results)
CREATE TABLE IF NOT EXISTS validation_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    flag_type VARCHAR(50) NOT NULL, -- 'missing_nif', 'math_error', 'date_invalid', etc.
    flag_code VARCHAR(20) NOT NULL, -- 'ES-21', 'ES-01', etc.
    severity VARCHAR(10) NOT NULL, -- 'error', 'warning', 'info'
    message TEXT NOT NULL,
    auto_fixable BOOLEAN DEFAULT FALSE,
    fixed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Collaborator Access (Accountant magic links)
CREATE TABLE IF NOT EXISTS collaborator_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    collaborator_email VARCHAR(255) NOT NULL,
    access_level VARCHAR(20) DEFAULT 'read_only', -- 'read_only', 'export'
    token VARCHAR(64) UNIQUE NOT NULL, -- Magic link token
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_fiscal_profile_id ON documents(fiscal_profile_id);
CREATE INDEX IF NOT EXISTS idx_documents_validation_status ON documents(validation_status);
CREATE INDEX IF NOT EXISTS idx_documents_file_hash ON documents(file_hash);
CREATE INDEX IF NOT EXISTS idx_validation_flags_document_id ON validation_flags(document_id);
CREATE INDEX IF NOT EXISTS idx_collaborator_access_token ON collaborator_access(token);
CREATE INDEX IF NOT EXISTS idx_collaborator_access_user_id ON collaborator_access(user_id);

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fiscal_profiles_updated_at BEFORE UPDATE ON fiscal_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
