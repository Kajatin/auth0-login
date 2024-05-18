import * as core from '@actions/core'

interface Auth0LoginRequest {
  client_id: string
  client_secret: string
  grant_type: string
  audience?: string
}

/**
 * The main function for the action.
 * @returns {Promise<void>} Resolves when the action is complete.
 */
export async function run(): Promise<void> {
  try {
    const tenantUrl: string = core.getInput('tenant-url', { required: true })
    const clientId: string = core.getInput('client-id', { required: true })
    const clientSecret: string = core.getInput('client-secret', {
      required: true
    })
    const audience: string = core.getInput('audience')
    const grantType: string =
      core.getInput('grant-type') || 'client_credentials'

    const requestBody = {
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: grantType
    } as Auth0LoginRequest

    if (audience) requestBody.audience = audience

    const auth0Url = `${tenantUrl.endsWith('/') ? tenantUrl : `${tenantUrl}/`}oauth/token`

    const response = await fetch(auth0Url, {
      method: 'POST',
      headers: {
        'content-type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      throw new Error(
        `Failed to authenticate with Auth0: ${response.statusText}`
      )
    }

    const responseBody = await response.json()
    const accessToken = responseBody.access_token

    core.info(`Access token: ${accessToken}`)

    // Set outputs for other workflow steps to use
    core.setOutput('access-token', accessToken)
  } catch (error) {
    // Fail the workflow run if an error occurs
    if (error instanceof Error) core.setFailed(error.message)
  }
}
