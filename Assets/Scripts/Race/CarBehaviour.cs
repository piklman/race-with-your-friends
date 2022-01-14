using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Base;

public class CarBehaviour : MonoBehaviour
{
    [SerializeField] private GameObject collisionSheet;
    private Sprite collision;

    // Base Classes
    private Vectors vectors = new Vectors();

    // Referencing values
    [SerializeField] private float maxEngineSpd; /* The maximum speed that any engine can reach without external forces (including with items).
    Used for speed ratios - for example particles are simulated at a speed of {CURRENT SPEED}/maxEngineSpd */
    [SerializeField] private float friction; // Will need to change based on terrain
    [SerializeField] private float rapidFrictionMultiplier;
    [SerializeField] private float unitSF; // Scale factor from stat values to real distance values

    // Components
    private Rigidbody2D rb;
    private ParticleSystem ps;
    private ParticleSystem.EmissionModule emissionModule;
    private ParticleSystem.ColorOverLifetimeModule colorOverLifetimeModule;
    [SerializeField] private ParticleSystem.MinMaxGradient regGradient;
    [SerializeField] private ParticleSystem.MinMaxGradient boostGradient;
    
    [SerializeField] private float regEmissionSF;
    [SerializeField] private float boostEmissionSF;
    [SerializeField] private float emissionSF;

    // Vehicle Physics
    [SerializeField] private float rawVelocity; // Only the speed + direction of thrust relative to current position.
    [SerializeField] private Stats baseStats;
    [SerializeField] private Stats stats;

    // Vehicle Stats
    [SerializeField] private float regMaxSpd; // Max speed without powerups
    [SerializeField] private float regAcc;
    [SerializeField] private float boostAcc;
    [SerializeField] private float thrusterAcc;

    [SerializeField] private float regPowerup;


    [SerializeField] private float driftSF;
    [SerializeField] private float powerupSF; // Scale factor for keeping stats similar in value while still balanced

    // Debug
    [SerializeField] private bool terminalVelocity;

    // Turning
    [SerializeField] private bool extraFriction;
    [SerializeField] private float turnSF;

    // Powerup
    [SerializeField] private string powerupItem;
    private bool boosting;

    void Start()
    {
        collision = collisionSheet.GetComponent<Sprite>();

        // Physics
        stats = baseStats;

        // Rigidbody
        rb = gameObject.GetComponent<Rigidbody2D>();

        // Particle System
        ps = gameObject.GetComponentInChildren<ParticleSystem>();

        emissionModule = ps.emission;
        emissionModule.enabled = true;

        emissionSF = regEmissionSF;

        colorOverLifetimeModule = ps.colorOverLifetime;
        colorOverLifetimeModule.enabled = true;
        colorOverLifetimeModule.color = regGradient;

        // Items
        boosting = false;
    }

    // Physics Functions
    void HandleRapidDeceleration()
    {
        var dec = rapidFrictionMultiplier * Mathf.Sign(rawVelocity);
        if (Mathf.Abs(rawVelocity) + dec > stats.spd)
        {
            if (rawVelocity - dec > stats.spd)
            {
                rawVelocity -= dec;
            }
            else if (rawVelocity + dec < -stats.spd)
            {
                rawVelocity += dec;
            }
        }
    }

    void HandleFriction()
    {
        if (rawVelocity > 0 && (rawVelocity - friction) > 0)
        {
            rawVelocity -= friction;
        }
        else if (rawVelocity < 0 && (rawVelocity - friction) < 0)
        {
            rawVelocity += friction;
        }
        else
        {
            rawVelocity = 0;
        }
    }

    void HandleMovement()
    {
        var deltaSpeed = Time.fixedDeltaTime * stats.acc;
        var accDir = 0f;

        if (Input.GetButton("Forward"))
        {
            accDir = 1f;
        }

        if (Input.GetButton("Brake"))
        {
            accDir -= 1f;
        }

		if (accDir == 0 && !vectors.VectorEqualsApprox(rb.velocity, Vector2.zero))
		{
			// The assumption was false. Car moving at const speed.
			emissionModule.rateOverTime = 0;
			rb.velocity = transform.up * rawVelocity;
		}

		else if (accDir == 0)
		{
			rb.velocity = Vector2.zero;
		}

		else
		{
            if (Mathf.Abs(rawVelocity + deltaSpeed) < stats.spd)
            {
                rawVelocity += deltaSpeed * accDir;
            }
            else if (Mathf.Abs(rawVelocity) > stats.spd)
            {
                HandleRapidDeceleration();
            }
            rb.velocity = transform.up * rawVelocity;
        }

        HandleFriction();
    }

    void HandleTurning()
    {
        var terminalAngularVelocity = 20f;

        // Below is used so the turning doesn't get ridiculous, and is still based on velocity.
        var speedUsed = rawVelocity;
        if (Mathf.Abs(rawVelocity) > Mathf.Abs(stats.spd))
            speedUsed = stats.spd;

        // Direction of rotation
        var dirotation = Input.GetAxis("Turn");

        // Set the change in angular velocity so we can use it to check if extra turning is allowed.
        var deltaAngularVelocity = dirotation * (stats.handling * speedUsed * Time.fixedDeltaTime);

        if (Mathf.Abs(rb.angularVelocity + deltaAngularVelocity) < terminalAngularVelocity)
        {
            rb.angularVelocity += deltaAngularVelocity;
        }
        else
            rb.angularVelocity = terminalAngularVelocity;
	}

    IEnumerator ResetAfterBoost(float time)
    {
        yield return new WaitForSeconds(time);
        stats.acc = regAcc * unitSF;
        stats.spd = regMaxSpd * unitSF;
        colorOverLifetimeModule.color = regGradient;
        emissionSF = regEmissionSF;
        boosting = false;
    }

    void ThrusterSlowdown()
    {
        if (rb.velocity.magnitude > stats.spd)
        {
            print("HI");
            rb.drag = friction * regPowerup;
            ThrusterSlowdown();
        }
        else
        {
            // Now car has slowed to an acceptable speed so drag returns to 0.
            rb.drag = 0;
            rb.velocity = new Vector2(rb.transform.up.x, rb.transform.up.y) * stats.spd;
        }
    }

    void HandlePowerups()
    {
        if (Input.GetButtonDown("Item"))
        {
            switch (powerupItem)
            {
                case "Boost":
                    stats.spd = maxEngineSpd * unitSF;
                    stats.acc = boostAcc * unitSF;
                    colorOverLifetimeModule.color = boostGradient;
                    emissionSF = boostEmissionSF;
                    boosting = true;

                    StartCoroutine(ResetAfterBoost(regPowerup * powerupSF));
                    powerupItem = "";
                    break;

                case "Thruster":
                    var itemY = Input.GetAxisRaw("ItemY");
                    var itemX = Input.GetAxisRaw("ItemX");
                    if (itemY != 0 && itemX == 0)
                    {
                        print("what");
                        rb.velocity += new Vector2(rb.transform.up.x, rb.transform.up.y) * thrusterAcc * regPowerup * itemY;
                    }
                    else if (itemY == 0 && itemX != 0)
                    {
                        print("correct");
                        // the fuck?
                        rb.velocity += new Vector2(rb.transform.right.x, rb.transform.right.y) * thrusterAcc * regPowerup * itemX;
                    }
                    else
                    {
                        print("default...");
                        rb.velocity += new Vector2(rb.transform.up.x, rb.transform.up.y) * thrusterAcc * regPowerup;
                    }

                    ThrusterSlowdown();
                    powerupItem = "";
                    break;

                default:
                    // User tried to use a powerup but there isn't one.
                    break;
            }
        }
    }

    void FixedUpdate()
    {
        // Particle System
        // Assume that the car is moving. See Acceleration for handling if it is not.
        emissionModule.rateOverTime = (rb.velocity.magnitude / maxEngineSpd) * emissionSF;

        // Turning
        if (Input.GetAxisRaw("Turn") != 0)
            HandleTurning();

        // Acceleration
        // issue - can't decelerate while accelerating - should cancel acc to 0
        // issue - not much control over the maximum speed (rb.velocity.magnitude + regAcc is never greater than or equal to regMaxSpd because of the linear drag)
        HandleMovement();

        // Powerups
        HandlePowerups();
    }

    // Update is called once per frame
    void Update()
    {
    }

	private void OnCollisionEnter2D(Collision2D collision)
	{
        rawVelocity = 0;
	}
}
