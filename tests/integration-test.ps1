#!/usr/bin/env pwsh
# =============================================================================
# MIANE - Full Integration Test Script
# Tests the complete user flow through all microservices via the API Gateway
# =============================================================================

param(
    [string]$GatewayUrl = "http://localhost:8080",
    [int]$StartupWaitSeconds = 10
)

$ErrorActionPreference = "Continue"
$totalTests = 0
$passedTests = 0
$failedTests = 0
$testResults = @()

function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-TestResult($name, $passed, $details = "") {
    $script:totalTests++
    if ($passed) {
        $script:passedTests++
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        $script:failedTests++
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        if ($details) { Write-Host "         $details" -ForegroundColor Yellow }
    }
    $script:testResults += @{ Name = $name; Passed = $passed; Details = $details }
}

function Invoke-Api {
    param(
        [string]$Method = "GET",
        [string]$Url,
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [string]$ContentType = "application/json"
    )
    
    $params = @{
        Method = $Method
        Uri = $Url
        ContentType = $ContentType
        Headers = $Headers
        ErrorAction = "Stop"
    }
    
    if ($Body -and $Method -ne "GET") {
        if ($Body -is [string]) {
            $params.Body = $Body
        } else {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
    }
    
    try {
        $response = Invoke-RestMethod @params
        return @{ Success = $true; Data = $response; StatusCode = 200 }
    }
    catch {
        $statusCode = 0
        $errorBody = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            try {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
            } catch {}
        }
        return @{ Success = $false; StatusCode = $statusCode; Error = $errorBody; Message = $_.Exception.Message }
    }
}

# =============================================================================
# TEST 0: Health Check - Wait for services to be ready
# =============================================================================
Write-Header "TEST 0: SERVICE HEALTH CHECKS"

Write-Host "  Waiting $StartupWaitSeconds seconds for services to stabilize..." -ForegroundColor Gray
Start-Sleep -Seconds $StartupWaitSeconds

# Check Gateway
$gatewayCheck = Invoke-Api -Url "$GatewayUrl/"
Write-TestResult "Gateway is reachable" $gatewayCheck.Success

# Check Identity directly
$identityCheck = Invoke-Api -Url "http://localhost:5127/auth/login" -Method "POST" -Body @{ email = "test"; password = "test" }
# We expect a 400/401 but NOT a connection error
$identityUp = ($identityCheck.Success -or $identityCheck.StatusCode -gt 0)
Write-TestResult "Identity API is reachable (port 5127)" $identityUp

# Check Trip directly 
$tripCheck = Invoke-Api -Url "http://localhost:5128/trips" -Headers @{ "X-User-Id" = [Guid]::NewGuid().ToString() }
$tripUp = ($tripCheck.Success -or $tripCheck.StatusCode -gt 0)
Write-TestResult "Trip API is reachable (port 5128)" $tripUp

# Check Expense directly
$expenseCheck = Invoke-Api -Url "http://localhost:5129/expenses/trip/$([Guid]::NewGuid())" -Headers @{ "X-User-Id" = [Guid]::NewGuid().ToString() }
$expenseUp = ($expenseCheck.Success -or $expenseCheck.StatusCode -gt 0)
Write-TestResult "Expense API is reachable (port 5129)" $expenseUp

# Check Notification directly
$notifCheck = Invoke-Api -Url "http://localhost:5130/notifications" -Headers @{ "X-User-Id" = [Guid]::NewGuid().ToString() }
$notifUp = ($notifCheck.Success -or $notifCheck.StatusCode -gt 0)
Write-TestResult "Notification API is reachable (port 5130)" $notifUp

if (-not $identityUp) {
    Write-Host ""
    Write-Host "  CRITICAL: Identity API not reachable. Aborting remaining tests." -ForegroundColor Red
    exit 1
}

# =============================================================================
# TEST 1: USER REGISTRATION & LOGIN (Identity Service)
# =============================================================================
Write-Header "TEST 1: USER REGISTRATION & LOGIN"

$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

# Register User A (trip creator)
$userAEmail = "alice_$timestamp@miane.test"
$registerA = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/register" -Body @{
    email = $userAEmail
    password = "Test@12345"
    fullName = "Alice Nguyen"
    phoneNumber = "+84901234567"
}
Write-TestResult "Register User A (Alice)" $registerA.Success "Status: $($registerA.StatusCode)"
if ($registerA.Success) {
    Write-Host "         Email: $userAEmail" -ForegroundColor Gray
}

# Register User B (trip joiner)
$userBEmail = "bob_$timestamp@miane.test"
$registerB = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/register" -Body @{
    email = $userBEmail
    password = "Test@12345"
    fullName = "Bob Tran"
    phoneNumber = "+84901234568"
}
Write-TestResult "Register User B (Bob)" $registerB.Success

# Register User C (another joiner)
$userCEmail = "charlie_$timestamp@miane.test"
$registerC = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/register" -Body @{
    email = $userCEmail
    password = "Test@12345"
    fullName = "Charlie Le"
    phoneNumber = "+84901234569"
}
Write-TestResult "Register User C (Charlie)" $registerC.Success

# Login User A
$loginA = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/login" -Body @{
    email = $userAEmail
    password = "Test@12345"
}
$tokenA = $null
if ($loginA.Success -and $loginA.Data.accessToken) {
    $tokenA = $loginA.Data.accessToken
    Write-TestResult "Login User A" $true
    Write-Host "         Token: $($tokenA.Substring(0, [Math]::Min(40, $tokenA.Length)))..." -ForegroundColor Gray
} else {
    Write-TestResult "Login User A" $false "Response: $($loginA | ConvertTo-Json -Depth 3)"
}

# Login User B
$loginB = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/login" -Body @{
    email = $userBEmail
    password = "Test@12345"
}
$tokenB = if ($loginB.Success) { $loginB.Data.accessToken } else { $null }
Write-TestResult "Login User B" ($tokenB -ne $null)

# Login User C
$loginC = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/login" -Body @{
    email = $userCEmail
    password = "Test@12345"
}
$tokenC = if ($loginC.Success) { $loginC.Data.accessToken } else { $null }
Write-TestResult "Login User C" ($tokenC -ne $null)

# Decode JWT to extract user IDs (simple base64 decode of payload)
function Get-JwtPayload($token) {
    $parts = $token.Split('.')
    $payload = $parts[1]
    # Fix base64 padding
    switch ($payload.Length % 4) {
        2 { $payload += "==" }
        3 { $payload += "=" }
    }
    $payload = $payload.Replace('-', '+').Replace('_', '/')
    $bytes = [Convert]::FromBase64String($payload)
    $json = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $json | ConvertFrom-Json
}

$userAId = $null; $userBId = $null; $userCId = $null
if ($tokenA) {
    $payloadA = Get-JwtPayload $tokenA
    $userAId = $payloadA.sub
    Write-Host "         User A ID: $userAId, Tier: $($payloadA.UserTier)" -ForegroundColor Gray
}
if ($tokenB) {
    $payloadB = Get-JwtPayload $tokenB
    $userBId = $payloadB.sub
    Write-Host "         User B ID: $userBId" -ForegroundColor Gray
}
if ($tokenC) {
    $payloadC = Get-JwtPayload $tokenC
    $userCId = $payloadC.sub
    Write-Host "         User C ID: $userCId" -ForegroundColor Gray
}

Write-TestResult "JWT contains UserTier claim" ($payloadA.UserTier -ne $null)

if (-not $tokenA -or -not $tokenB) {
    Write-Host ""
    Write-Host "  CRITICAL: Login failed. Cannot continue tests." -ForegroundColor Red
    exit 1
}

# =============================================================================
# TEST 2: TRIP SERVICE - Create & Join Trip (via Gateway)
# =============================================================================
Write-Header "TEST 2: TRIP SERVICE - CREATE & JOIN"

$authHeadersA = @{ Authorization = "Bearer $tokenA" }
$authHeadersB = @{ Authorization = "Bearer $tokenB" }
$authHeadersC = @{ Authorization = "Bearer $tokenC" }

# Create Trip (User A)
$createTrip = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips" -Body @{
    name = "Da Nang Beach Trip 2026"
    description = "Summer vacation to Da Nang with friends!"
    destination = "Da Nang, Vietnam"
    baseCurrency = "VND"
} -Headers $authHeadersA

$tripId = $null; $inviteCode = $null
if ($createTrip.Success) {
    $tripId = $createTrip.Data.tripId
    $inviteCode = $createTrip.Data.inviteCode
    Write-TestResult "Create Trip (User A)" $true
    Write-Host "         Trip ID: $tripId" -ForegroundColor Gray
    Write-Host "         Invite Code: $inviteCode" -ForegroundColor Gray
} else {
    Write-TestResult "Create Trip (User A)" $false "Status: $($createTrip.StatusCode), Error: $($createTrip.Error | ConvertTo-Json -Depth 3)"
}

# Get Trip Details
if ($tripId) {
    $getTrip = Invoke-Api -Url "$GatewayUrl/trips/$tripId" -Headers $authHeadersA
    if ($getTrip.Success) {
        Write-TestResult "Get Trip Details" $true
        Write-Host "         Name: $($getTrip.Data.name), Members: $($getTrip.Data.members.Count)" -ForegroundColor Gray
        Write-TestResult "Trip has 1 member (owner)" ($getTrip.Data.members.Count -eq 1)
    } else {
        Write-TestResult "Get Trip Details" $false "Status: $($getTrip.StatusCode)"
    }
}

# User B joins via invite code
if ($inviteCode) {
    $joinTrip = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips/join" -Body @{
        inviteCode = $inviteCode
        nickName = "Bobby"
    } -Headers $authHeadersB

    if ($joinTrip.Success) {
        Write-TestResult "User B Joins Trip via Invite Code" $true
        Write-Host "         Member Count: $($joinTrip.Data.memberCount)" -ForegroundColor Gray
    } else {
        Write-TestResult "User B Joins Trip via Invite Code" $false "Status: $($joinTrip.StatusCode), Error: $($joinTrip.Error | ConvertTo-Json -Depth 3)"
    }
}

# User C joins
if ($inviteCode) {
    $joinC = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips/join" -Body @{
        inviteCode = $inviteCode
    } -Headers $authHeadersC
    Write-TestResult "User C Joins Trip" $joinC.Success
}

# Verify 3 members
if ($tripId) {
    $getTrip2 = Invoke-Api -Url "$GatewayUrl/trips/$tripId" -Headers $authHeadersA
    if ($getTrip2.Success) {
        Write-TestResult "Trip now has 3 members" ($getTrip2.Data.members.Count -eq 3)
    }
}

# Test duplicate join (should fail with 409 Conflict)
if ($inviteCode) {
    $dupJoin = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips/join" -Body @{
        inviteCode = $inviteCode
    } -Headers $authHeadersB
    Write-TestResult "Duplicate join returns Conflict" ($dupJoin.StatusCode -eq 409)
}

# Test Get User Trips
$userTrips = Invoke-Api -Url "$GatewayUrl/trips" -Headers $authHeadersA
if ($userTrips.Success) {
    Write-TestResult "Get User A's Trips" $true
    Write-Host "         Trip Count: $($userTrips.Data.Count)" -ForegroundColor Gray
} else {
    Write-TestResult "Get User A's Trips" $false
}

# =============================================================================
# TEST 3: EXPENSE SERVICE - Add Expenses & Check Balances
# =============================================================================
Write-Header "TEST 3: EXPENSE SERVICE - EXPENSES & DEBT"

# Add Expense 1: Alice pays for dinner (equal split)
if ($tripId -and $userAId -and $userBId -and $userCId) {
    $expense1 = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses" -Body @{
        tripId = $tripId
        description = "Dinner at Hai San restaurant"
        amount = 900000
        currency = "VND"
        tripBaseCurrency = "VND"
        splitType = 0  # Equal
        splits = @(
            @{ userId = $userAId; amount = $null; percentage = $null },
            @{ userId = $userBId; amount = $null; percentage = $null },
            @{ userId = $userCId; amount = $null; percentage = $null }
        )
    } -Headers $authHeadersA

    if ($expense1.Success) {
        Write-TestResult "Add Expense 1: Dinner 900K VND (Equal split)" $true
        Write-Host "         Expense ID: $($expense1.Data.expenseId)" -ForegroundColor Gray
        Write-Host "         Converted: $($expense1.Data.convertedAmount) $($expense1.Data.baseCurrency)" -ForegroundColor Gray
    } else {
        Write-TestResult "Add Expense 1: Dinner 900K VND" $false "Status: $($expense1.StatusCode), Error: $($expense1.Error | ConvertTo-Json -Depth 3)"
    }

    # Add Expense 2: Bob pays for hotel (custom split)
    $expense2 = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses" -Body @{
        tripId = $tripId
        description = "Hotel Golden Bay 2 nights"
        amount = 2400000
        currency = "VND"
        tripBaseCurrency = "VND"
        splitType = 1  # Custom
        splits = @(
            @{ userId = $userAId; amount = 800000; percentage = $null },
            @{ userId = $userBId; amount = 800000; percentage = $null },
            @{ userId = $userCId; amount = 800000; percentage = $null }
        )
    } -Headers $authHeadersB

    if ($expense2.Success) {
        Write-TestResult "Add Expense 2: Hotel 2.4M VND (Custom split)" $true
    } else {
        Write-TestResult "Add Expense 2: Hotel 2.4M VND" $false "Status: $($expense2.StatusCode), Error: $($expense2.Error | ConvertTo-Json -Depth 3)"
    }

    # Add Expense 3: Multi-currency - Charlie pays in USD
    $expense3 = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses" -Body @{
        tripId = $tripId
        description = "Grab rides (paid in USD)"
        amount = 15.50
        currency = "USD"
        tripBaseCurrency = "VND"
        splitType = 0  # Equal
        splits = @(
            @{ userId = $userAId; amount = $null; percentage = $null },
            @{ userId = $userBId; amount = $null; percentage = $null },
            @{ userId = $userCId; amount = $null; percentage = $null }
        )
    } -Headers $authHeadersC

    if ($expense3.Success) {
        Write-TestResult "Add Expense 3: Grab `$15.50 USD -> VND (multi-currency)" $true
        Write-Host "         Converted: $($expense3.Data.convertedAmount) VND (rate applied)" -ForegroundColor Gray
    } else {
        Write-TestResult "Add Expense 3: Multi-currency" $false "Status: $($expense3.StatusCode)"
    }
}

# Get all trip expenses
if ($tripId) {
    $allExpenses = Invoke-Api -Url "$GatewayUrl/expenses/trip/$tripId" -Headers $authHeadersA
    if ($allExpenses.Success) {
        Write-TestResult "Get Trip Expenses" $true
        Write-Host "         Total Expenses: $($allExpenses.Data.Count)" -ForegroundColor Gray
        Write-TestResult "3 expenses recorded" ($allExpenses.Data.Count -eq 3)
    } else {
        Write-TestResult "Get Trip Expenses" $false "Status: $($allExpenses.StatusCode)"
    }
}

# Get simplified debt balances
if ($tripId) {
    $balances = Invoke-Api -Url "$GatewayUrl/expenses/trip/$tripId/balances" -Headers $authHeadersA
    if ($balances.Success) {
        Write-TestResult "Get Simplified Debt Balances" $true
        Write-Host "         Unsettled Debts: $($balances.Data.unsettledDebts.Count)" -ForegroundColor Gray
        foreach ($debt in $balances.Data.unsettledDebts) {
            Write-Host "           $($debt.fromUserId.Substring(0,8))... owes $($debt.toUserId.Substring(0,8))... -> $($debt.amount) $($debt.currency)" -ForegroundColor Gray
        }
        Write-TestResult "Debt simplification produced results" ($balances.Data.unsettledDebts.Count -gt 0)
    } else {
        Write-TestResult "Get Debt Balances" $false "Status: $($balances.StatusCode)"
    }

    # Settle one debt
    if ($balances.Success -and $balances.Data.unsettledDebts.Count -gt 0) {
        $debtToSettle = $balances.Data.unsettledDebts[0]
        $settleResult = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses/settle" -Body @{
            debtRecordId = $debtToSettle.debtRecordId
        } -Headers $authHeadersB  # Bob settles

        if ($settleResult.Success -or $settleResult.StatusCode -eq 204 -or $settleResult.StatusCode -eq 200) {
            Write-TestResult "Settle Debt: $($debtToSettle.amount) $($debtToSettle.currency)" $true
        } else {
            Write-TestResult "Settle Debt" $false "Status: $($settleResult.StatusCode)"
        }

        # Verify settlement
        $balances2 = Invoke-Api -Url "$GatewayUrl/expenses/trip/$tripId/balances" -Headers $authHeadersA
        if ($balances2.Success) {
            Write-TestResult "Settlement reflected in balances" ($balances2.Data.settledDebts.Count -gt 0)
        }
    }
}

# =============================================================================
# TEST 4: TRIP POOL (Shared Fund)
# =============================================================================
Write-Header "TEST 4: TRIP POOL (SHARED FUND)"

if ($tripId) {
    # Contribute to pool
    $contrib1 = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses/pool/contribute" -Body @{
        tripId = $tripId
        amount = 500000
        currency = "VND"
    } -Headers $authHeadersA
    
    if ($contrib1.Success) {
        Write-TestResult "Alice contributes 500K VND to pool" $true
        Write-Host "         Pool Balance: $($contrib1.Data.newBalance) VND" -ForegroundColor Gray
    } else {
        Write-TestResult "Pool contribution (Alice)" $false "Status: $($contrib1.StatusCode)"
    }

    $contrib2 = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses/pool/contribute" -Body @{
        tripId = $tripId
        amount = 500000
        currency = "VND"
    } -Headers $authHeadersB
    Write-TestResult "Bob contributes 500K VND to pool" $contrib2.Success

    # Check pool
    $pool = Invoke-Api -Url "$GatewayUrl/expenses/pool/$tripId" -Headers $authHeadersA
    if ($pool.Success) {
        Write-TestResult "Get Pool Balance" $true
        Write-Host "         Balance: $($pool.Data.balance) VND" -ForegroundColor Gray
        Write-Host "         Contributions: $($pool.Data.contributions.Count)" -ForegroundColor Gray
        Write-TestResult "Pool balance is 1,000,000 VND" ($pool.Data.balance -eq 1000000)
    } else {
        Write-TestResult "Get Pool Balance" $false "Status: $($pool.StatusCode)"
    }
}

# =============================================================================
# TEST 5: NOTIFICATION SERVICE
# =============================================================================
Write-Header "TEST 5: NOTIFICATION SERVICE"

# Get notifications
$notifs = Invoke-Api -Url "http://localhost:5130/notifications?page=1&pageSize=10" -Headers @{ "X-User-Id" = $userAId }
if ($notifs.Success) {
    Write-TestResult "Get Notification History" $true
    Write-Host "         Notifications: $($notifs.Data.notifications.Count), Unread: $($notifs.Data.unreadCount)" -ForegroundColor Gray
} else {
    Write-TestResult "Get Notification History" $false "Status: $($notifs.StatusCode)"
}

# =============================================================================
# TEST 6: TRIP MANAGEMENT - Update & Member Operations
# =============================================================================
Write-Header "TEST 6: TRIP MANAGEMENT"

if ($tripId) {
    # Update trip (Owner)
    $updateTrip = Invoke-Api -Method "PUT" -Url "$GatewayUrl/trips/$tripId" -Body @{
        name = "Da Nang Beach Trip 2026 (Updated!)"
        description = "Summer vacation - updated itinerary"
    } -Headers $authHeadersA
    Write-TestResult "Update Trip Name (Owner)" ($updateTrip.Success -or $updateTrip.StatusCode -eq 204 -or $updateTrip.StatusCode -eq 200)

    # Verify update
    $verify = Invoke-Api -Url "$GatewayUrl/trips/$tripId" -Headers $authHeadersA
    if ($verify.Success) {
        Write-TestResult "Trip name updated" ($verify.Data.name -like "*Updated*")
    }

    # Non-member tries to view (should fail 403)
    # Create a new user who is NOT a member
    $outsiderEmail = "outsider_$timestamp@miane.test"
    Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/register" -Body @{
        email = $outsiderEmail; password = "Test@12345"; fullName = "Outsider"; phoneNumber = "+84909999999"
    } | Out-Null
    $loginOutsider = Invoke-Api -Method "POST" -Url "$GatewayUrl/auth/login" -Body @{
        email = $outsiderEmail; password = "Test@12345"
    }
    if ($loginOutsider.Success) {
        $outsiderToken = $loginOutsider.Data.accessToken
        $outsiderView = Invoke-Api -Url "$GatewayUrl/trips/$tripId" -Headers @{ Authorization = "Bearer $outsiderToken" }
        Write-TestResult "Non-member cannot view trip (403 Forbidden)" ($outsiderView.StatusCode -eq 403)
    }

    # User C leaves trip
    $leaveResult = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips/$tripId/leave" -Headers $authHeadersC
    Write-TestResult "User C Leaves Trip" ($leaveResult.Success -or $leaveResult.StatusCode -eq 204 -or $leaveResult.StatusCode -eq 200)

    # Verify member count dropped
    $afterLeave = Invoke-Api -Url "$GatewayUrl/trips/$tripId" -Headers $authHeadersA
    if ($afterLeave.Success) {
        Write-TestResult "Trip has 2 members after leave" ($afterLeave.Data.members.Count -eq 2)
    }
}

# =============================================================================
# TEST 7: ERROR HANDLING & EDGE CASES
# =============================================================================
Write-Header "TEST 7: ERROR HANDLING & EDGE CASES"

# Invalid invite code
$badJoin = Invoke-Api -Method "POST" -Url "$GatewayUrl/trips/join" -Body @{
    inviteCode = "INVALID1"
} -Headers $authHeadersA
Write-TestResult "Invalid invite code returns 404" ($badJoin.StatusCode -eq 404)

# Missing auth header (through gateway)
$noAuth = Invoke-Api -Url "$GatewayUrl/trips"
Write-TestResult "No auth token returns 401" ($noAuth.StatusCode -eq 401)

# Negative expense amount (should fail validation)
if ($tripId) {
    $negExpense = Invoke-Api -Method "POST" -Url "$GatewayUrl/expenses" -Body @{
        tripId = $tripId
        description = "Bad expense"
        amount = -100
        currency = "VND"
        tripBaseCurrency = "VND"
        splitType = 0
        splits = @(@{ userId = $userAId; amount = $null; percentage = $null })
    } -Headers $authHeadersA
    Write-TestResult "Negative amount returns 400 (validation)" ($negExpense.StatusCode -eq 400)
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
# =============================================================================
Write-Host ""
Write-Host "  Total Tests:  $totalTests" -ForegroundColor White
Write-Host "  Passed:       $passedTests" -ForegroundColor Green
Write-Host "  Failed:       $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host ""

$pct = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
if ($failedTests -eq 0) {
    Write-Host "  SUCCESS: ALL TESTS PASSED ($pct%)" -ForegroundColor Green
} else {
    Write-Host "  WARNING: $failedTests TESTS FAILED ($pct% pass rate)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Failed tests:" -ForegroundColor Yellow
    $testResults | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "    - $($_.Name): $($_.Details)" -ForegroundColor Red
    }
}
Write-Host ""
